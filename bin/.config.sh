#!/usr/bin/env bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value


#######################################
## Configuration
#######################################

GETOPT='getopt'
unamestr=`uname`
if [ "$unamestr" == 'FreeBSD' -o "$unamestr" == 'Darwin'  ]; then
  GETOPT="$(brew --prefix)/opt/gnu-getopt/bin/getopt"
fi

if [ -z "`which $GETOPT`" ]; then
    echo "[ERROR] $GETOPT not installed"
    echo "        make sure gnu-getopt is installed"
    echo "        MacOS: brew install gnu-getopt"
    exit 1
fi

if docker compose &> /dev/null
then
    DC='docker compose'
elif command -v docker-compose &> /dev/null
then
    DC='docker-compose'
else
    echo "[ERROR] docker compose not installed"
    exit 1
fi

#######################################
## Functions
#######################################

errorMsg() {
    echo "[ERROR] $*"
}

logMsg() {
    echo " * $*"
}

sectionHeader() {
    echo "*** $* ***"
}

execInDir() {
    echo "[RUN :: $1] $2"

    sh -c "cd \"$1\" && $2"
}

dockerContainerId() {
    echo "$($DC ps -q "$1" 2> /dev/null || echo "")"
}

dockerExec() {
    docker exec -i "$($DC ps -q app)" "$@"
}

dockerExecMySQL() {
    docker exec -i "$($DC ps -q mysql)" "$@"
}

dockerCopyFrom() {
    PATH_DOCKER="$1"
    PATH_HOST="$2"
    docker cp "$($DC ps -q app):${PATH_DOCKER}" "${PATH_HOST}"
}
dockerCopyTo() {
    PATH_HOST="$1"
    PATH_DOCKER="$2"
    docker cp "${PATH_HOST}" "$($DC ps -q app):${PATH_DOCKER}"
}
