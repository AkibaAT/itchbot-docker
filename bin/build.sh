#!/usr/bin/env bash

if ! command -v yq &>/dev/null; then
  echo "yq missing! Please install latest v4 binary from https://github.com/mikefarah/yq/releases"
  exit 1
fi

if [ -z "`which trivy`" ]; then
  echo "[ERROR] trivy not installed"
  echo "        make sure trivy is installed"
  echo "        MacOS: brew install trivy"
  exit 1
fi

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.config.sh"

# read the options
TEMP=$(${GETOPT} -o p --long push -n 'build.sh' -- "$@")
eval set -- "$TEMP"

PUSH=0

# extract options and their arguments into variables.
while true; do
  case "$1" in
  -p | --push)
    PUSH=1
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Unrecognized parameter passed!"
    exit 1
    ;;
  esac
done

# Load all available service as $services
services=($(${DC} -f docker-compose.yml config --services | tr '\n' ' '))

# accept non-options as image names
if [ ${#@} != 0 ]; then
  unset services
  services=("$@")
fi

for serviceIndex in "${!services[@]}"; do
  image=$($DC config | yq e .services."${services[serviceIndex]}".image)
  # Only try to build images for our registry
  if [[ "${image}" == "ghcr.io/akibaat/"* ]]; then
      # Check if the current build version already exists in remote registry; Abort if it does
      docker manifest inspect "${image}" >/dev/null 2>&1 &&
        echo "Image ${image} already exists in registry, skipping" &&
        unset 'services[serviceIndex]'
    else
      unset 'services[serviceIndex]'
  fi
done

for service in "${services[@]}"; do
  if [ "$service" == "" ]; then continue; fi
  platform=$(yq e .services."${service}".platform docker-compose.yml)
  if [ "$platform" == "null" ]; then
    arch="$(uname -m)"
    case "$arch" in
        x86_64) export runplatform=linux/amd64 ;;
        aarch64) export runplatform=linux/arm64 ;;
        arm64) export runplatform=linux/arm64 ;;
    esac
    buildplatforms=linux/amd64,linux/arm64
  else
    runplatform=$platform
    buildplatforms=$platform
  fi
  imageWithRawTag=$(yq e .services."${service}".image docker-compose.yml)
  variants=(prod)
  if [[ $imageWithRawTag =~ "$" ]]; then
    variants=(dev prod)
  fi
  if [ $PUSH = 1 ]; then
    platforms=${buildplatforms}
    echo "Building and push architectures ${platforms}"
  else
    push=""
    platforms=${runplatform}
    echo "Building architecture ${platforms}"
  fi
  for variant in "${variants[@]}"; do
    imageWithTag=$(DOCKER_ENVIRONMENT=${variant} $DC config | yq e .services."${service}".image)
    imageSplit=($(echo ${imageWithTag} | tr ':' ' '))
    if [ $PUSH = 1 ]; then
      push="--set ${service}.tags=${imageSplit[0]}:latest-${variant} --push ${service}"
    else
      push="--load ${service}"
    fi
    if [ $PUSH = 1 ]; then
      cachePush="--set ${service}.cache-to=type=registry,ref=${imageSplit[0]}:build-cache-${variant},mode=max"
    else
      cachePush=""
    fi
    DOCKER_ENVIRONMENT=${variant} docker buildx bake \
      --provenance=false \
      -f docker-compose.yml \
      -f docker-compose.build.yml \
      --pull \
      --set ${service}.cache-from=type=registry,ref=${imageSplit[0]}:build-cache-${variant} \
      ${cachePush:-} \
      --set ${service}.platform=${platforms} \
      --set ${service}.tags=${imageWithTag} \
      ${push:-}
    status=$?
    if test $status -eq 0; then
      echo "Build of ${service} (${variant}) completed successfully."
    else
      echo "Build error in service ${service} (${variant}), aborting!" && exit $status
    fi
    echo "Running security scan on ${service} (${variant})"
    trivy image --exit-code 1 --ignore-unfixed --scanners vuln --vuln-type os --severity HIGH,CRITICAL ${imageWithTag}
    if [ $PUSH = 1 ]; then
      echo "Push of ${service} (${variant}) completed."
    fi
  done
done
