#!/bin/bash

#Pull in Git Submodules
echo "Bringing in submodule dependencies for Vagrant projects"
git submodule init
git submodule update

echo "Starting NFS Server (hostname:nfs-server)"
echo ""
#Start the NFS Server first
cd nfs-server;vagrant up

echo ""
echo ""

echo "Starting Stash and PostgreSQL Master (hostname:stash-server)"
echo ""
#Start production_master second
cd ../stash-server;vagrant up

echo ""
echo ""

echo "Starting Production PostgreSQL Standby (hostname:production-db-standby)"
echo ""
cd ../production-standby;vagrant up

echo ""
echo ""

echo "Boot strap script is completed."
