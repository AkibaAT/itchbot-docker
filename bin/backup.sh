#!/usr/bin/env bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.config.sh"

if [ "$#" -lt 1 ]; then
    echo "No database name defined"
    exit 1
fi

mkdir -p -- "${BACKUP_DIR}"

if [[ -n "$(dockerContainerId mysql)" ]]; then
    if [ -f "${BACKUP_DIR}/$1.sql.gz" ]; then
        logMsg "Removing old backup file..."
        rm -f -- "${BACKUP_DIR}/$1.sql.gz"
    fi

    logMsg "Starting MySQL backup..."
    DB_ROOT_PASSWORD=$(dockerExecMySQL printenv DB_ROOT_PASSWORD)
    dockerExecMySQL sh -c "MYSQL_PWD=\"${DB_ROOT_PASSWORD}\" mysqldump -h mysql -uroot --opt --single-transaction --events --routines --comments $1" | gzip > "${BACKUP_DIR}/$1.sql.gz"
    logMsg "Finished"
else
    echo " * Skipping mysql backup, no such container"
fi

