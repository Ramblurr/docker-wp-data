#!/bin/bash
#
# Creates a database and a user with suitable privileges for a wordpress install
# Based on tutum's docker-mysql run script: https://github.com/tutumcloud/tutum-docker-mysql

# Requires the env vars:
# DB_HOST, DB_PORT, MYSQL_USER, MYSQL_PASS, DATA_DB_USER, DATA_DB_PASS, DATA_DB_NAME

set -u
set -o pipefail

DB_HOST=${DB_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_HOST=${DB_1_PORT_3306_TCP_ADDR:-${DB_HOST}}
DB_PORT=${DB_PORT_3306_TCP_PORT:-${DB_PORT}}
DB_PORT=${DB_1_PORT_3306_TCP_PORT:-${DB_PORT}}
MYSQL_USER=${SQLDATA_ENV_MYSQL_USER:-${DB_ADMIN_USER}}
MYSQL_PASS=${SQLDATA_ENV_MYSQL_PASS:-${DB_ADMIN_PASS}}

if [[ -z "$MYSQL_USER" ]] || [[ -z "$MYSQL_PASS" ]]; then
    echo "SQLDATA_ENV_MYSQL_USER and _PASS nor DB_ADMIN_USER _PASS are set. Aborting."
    exit 1;
fi

echo "========================================="
echo "Creating Database & User"
echo ""
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo ""
echo "MYSQL_USER: $MYSQL_USER"
echo "MYSQL_PASS: $MYSQL_PASS"
echo ""
echo "DATA_DB_USER: $DATA_DB_USER"
echo "DATA_DB_PASS: $DATA_DB_PASS"
echo "DATA_DB_NAME: $DATA_DB_NAME"
echo "========================================="

for ((i=0;i<10;i++))
do
    DB_CONNECTABLE=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e 'status' >/dev/null 2>&1; echo "$?")
    if [[ DB_CONNECTABLE -eq 0 ]]; then
        break
    fi
    sleep 5
done

if [[ $DB_CONNECTABLE -eq 0 ]]; then
    DB_EXISTS=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e "SHOW DATABASES LIKE '"$DATA_DB_NAME"';" 2>&1 | grep "$DATA_DB_NAME" > /dev/null ; echo "$?")

    if [[ DB_EXISTS -eq 1 ]]; then
        echo "=> Creating database $DATA_DB_NAME"
        RET=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e "CREATE DATABASE $DATA_DB_NAME")
        if [[ RET -ne 0 ]]; then
            echo "Cannot create database."
            exit RET
        fi
        if [ -f /initial_db.sql ]; then
            echo "=> Loading initial database data to $DATA_DB_NAME"
            RET=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT $DATA_DB_NAME < /initial_db.sql)
            if [[ RET -ne 0 ]]; then
                echo "Cannot load initial database data"
                exit RET
            fi
        fi
        echo "=> Done!"
    else
        echo "=> Skipped creation of database $DATA_DB_NAME – it already exists."
    fi

    USER_EXISTS=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e "SELECT User FROM mysql.user WHERE user = '"$DATA_DB_USER"';" 2>&1 | grep "$DATA_DB_USER" > /dev/null ; echo "$?")
    if [[ USER_EXISTS -eq 1 ]]; then
        echo "=> Creating user $DATA_DB_USER"
        RET=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e "CREATE USER '$DATA_DB_USER'@'%' IDENTIFIED BY '$DATA_DB_PASS';")
        if [[ RET -ne 0 ]]; then
            echo "Cannot create user"
            exit RET
        fi
        echo "=> Done!"

        RET=$(mysql -u$MYSQL_USER -p$MYSQL_PASS -h$DB_HOST -P$DB_PORT -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON \`$DATA_DB_NAME\`.* TO '$DATA_DB_USER'@'%';")
        echo "=> Granting privileges to $DATA_DB_USER"
        if [[ RET -ne 0 ]]; then
            echo "Cannot grant user privileges"
            exit RET
        fi
        echo "=> Done!"
    else
        echo "=> Skipped creation of user $DATA_DB_USER – it already exists."
    fi
else
    echo "Cannot connect to Mysql"
    exit $DB_CONNECTABLE
fi

# all good
exit 0
