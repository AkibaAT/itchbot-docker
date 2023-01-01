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

# Load all available service as $services
services=($(${DC} -f docker-compose.yml config --services | tr '\n' ' '))

# accept non-options as image names
if [ ${#@} != 0 ]; then
  unset services
  services=("$@")
fi

scan_images () {
  for serviceIndex in "${!services[@]}"; do
    imageWithRawTag=$(yq e .services."${services[serviceIndex]}".image docker-compose.yml)
    if [[ "${imageWithRawTag}" == "registry.gitlab.com/rejaku/"* ]]; then
      image=$($DC config | yq e .services."${services[serviceIndex]}".image)
      variants=(prod)
      if [[ $imageWithRawTag =~ "$" ]]; then
        variants=(dev prod)
      fi
      for variant in "${variants[@]}"; do
        imageWithTag=$(DOCKER_ENVIRONMENT=${variant} $DC config | yq e .services."${services[serviceIndex]}".image)
        trivy image --exit-code $1 --ignore-unfixed --security-checks vuln --vuln-type os --severity HIGH,CRITICAL --no-progress ${imageWithTag}
      done
    fi
  done
}

scan_images "0"
scan_images "1"
