#!/bin/bash

#Cleanup old backup - directory must be empty for pg_basebackup to work
rm -f /mnt/db_bkup/* 2> /dev/null

#Run backup must be as postgres user
if [[ $USER != "postgres" ]]; then
  echo "Must be run as postgres user!"
  exit 1
fi
pg_basebackup -h 172.16.254.11 -D /mnt/db_bkup/ -v -Ft -z

