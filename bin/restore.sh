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
    BACKUP_MYSQL_FILE=
    BACKUP_MYSQL_FILE_COMMAND=
    if [ -n "${1:-}" ]; then
        if [ -f "${BACKUP_DIR}/$1.sql" ]; then
            BACKUP_MYSQL_FILE=$1.sql
            BACKUP_MYSQL_FILE_COMMAND=cat
        elif [ -f "${BACKUP_DIR}/$1.sql.gz" ]; then
            BACKUP_MYSQL_FILE=$1.sql.gz
            BACKUP_MYSQL_FILE_COMMAND="gzip -dc"
        elif [ -f "${BACKUP_DIR}/$1.sql.bz2" ]; then
            BACKUP_MYSQL_FILE=$1.sql.bz2
            BACKUP_MYSQL_FILE_COMMAND=bzcat
        elif [ -f "${BACKUP_DIR}/$1.sql.zip" ]; then
            BACKUP_MYSQL_FILE=$1.sql.zip
            BACKUP_MYSQL_FILE_COMMAND="unzip -p"
        fi
    fi
    if [ -f "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}" ]; then
        logMsg "Starting MySQL restore..."
        DB_ROOT_PASSWORD=$(dockerExecMySQL printenv DB_ROOT_PASSWORD)
        if [ "$1" != "mysql" ]; then
            dockerExecMySQL sh -c "MYSQL_PWD=\"${DB_ROOT_PASSWORD}\" mysql -h mysql -uroot -e \"DROP DATABASE IF EXISTS $1; CREATE DATABASE $1;\""
        fi
        eval ${BACKUP_MYSQL_FILE_COMMAND} "${BACKUP_DIR}/${BACKUP_MYSQL_FILE}" | dockerExecMySQL sh -c "MYSQL_PWD=\"${DB_ROOT_PASSWORD}\" mysql -h mysql -uroot $1"
        if [ -f .env ]; then
            set -o allexport; source .env; set +o allexport
        fi
        if [ -f "${CONFIG_DIR}/${DOCKER_ENVIRONMENT:-prod}/$1.sql" ]; then
            cat ${CONFIG_DIR}/${DOCKER_ENVIRONMENT:-prod}/${1}.sql | dockerExecMySQL sh -c "MYSQL_PWD=\"${DB_ROOT_PASSWORD}\" mysql -h mysql -uroot $1"
        fi
        echo "FLUSH PRIVILEGES;" | dockerExecMySQL sh -c "MYSQL_PWD=\"${DB_ROOT_PASSWORD}\" mysql -h mysql -uroot"
        logMsg "Finished"
    else
        errorMsg "Supported MySQL backup file format not found"
        exit 1
    fi
else
    echo "No MySQL container found"
fi

