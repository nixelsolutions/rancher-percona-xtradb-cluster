#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" -o -z "${PXC_SST_PASSWORD}" ]; then
   echo "*** ERROR: you need to define PXC_SST_PASSWORD environment variable - Exiting ..."
   exit 1

if [ "${PXC_ROOT_PASSWORD}" == "**ChangeMe**" -o -z "${ROOT_PASSWORD}" ]; then
   echo "*** ERROR: you need to define PXC_ROOT_PASSWORD environment variable - Exiting ..."
   exit 1
fi

if [ "${SERVICE_NAME}" == "**ChangeMe**" -o -z "${SERVICE_NAME}" ]; then
   echo "*** ERROR: you need to define SERVICE_NAME environment variable - Exiting ..."
   exit 1
fi

# Configure the cluster (replace required parameters)
sleep 5
echo "=> Configuring PXC cluster"
export PXC_NODES=`dig +short $SERVICE_NAME | sed "s/ /,/g"`
export MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
change_pxc_nodes.sh "${PXC_NODES}"
echo "root:${PXC_ROOT_PASSWORD}" | chpasswd
perl -p -i -e "s/PXC_SST_PASSWORD/${PXC_SST_PASSWORD}/g" ${PXC_CONF}
perl -p -i -e "s/MY_RANCHER_IP/${MY_RANCHER_IP}/g" ${PXC_CONF}
chown -R mysql:mysql ${PXC_VOLUME}

echo "==========================================="
echo "When you need to use this database cluster in an application"
echo "remember that your MySQL root password is ${PXC_ROOT_PASSWORD}"
echo "===========================================" 

# If this container is not configured, just configure it
if [ ! -e ${PXC_CONF_FLAG} ]; then
   # Bootstrap the cluster - Needed for first container initialization
   # Only first server on PXC_NODES list is bootstraping the cluster
   if [ "${MY_RANCHER_IP}" == `echo "${PXC_NODES}" | head -1` ]; then
      bootstrap-pxc.sh || exit 1
   # Don't bootstrap the cluster, just join it - Needed for subsequent containers initialization
   else 
      join-cluster.sh || exit 1
   fi
else
   # If this container is already configured, just start it
   echo "=> Starting PXC Cluster"
   /usr/bin/supervisord
fi