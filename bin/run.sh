#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" -o -z "${PXC_SST_PASSWORD}" ]; then
   echo "*** ERROR: you need to define PXC_SST_PASSWORD environment variable - Exiting ..."
   exit 1
fi

if [ "${PXC_ROOT_PASSWORD}" == "**ChangeMe**" -o -z "${PXC_ROOT_PASSWORD}" ]; then
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
PXC_NODES=`dig +short ${SERVICE_NAME} | sort`
export PXC_NODES=`echo ${PXC_NODES} | sed "s/ /,/g"`
if [ -z "${PXC_NODES}" ]; then
   echo "*** ERROR: Could not determine which containers are part of this service."
   echo "*** Is this service named \"${SERVICE_NAME}\"? If not, please regenerate the service"
   echo "*** and add SERVICE_NAME environment variable which value should be equal to this service name"
   echo "*** Exiting ..."
   exit 1
fi
export MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
if [ -z "${MY_RANCHER_IP}" ]; then
   echo "*** ERROR: Could not determine this container Rancher IP - Exiting ..."
   exit 1
fi
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
BOOTSTRAPED=false
if [ ! -e ${PXC_CONF_FLAG} ]; then
   # Ask other containers if they're already configured
   # If so, I'm joining the cluster
   # If not, I'm bootstraping only if I'm first node in PXC_NODES - needed for cluster initialization
   for node in `echo "${PXC_NODES}" | sed "s/,/ /g"`; do
      # Skip myself
      if [ "${MY_RANCHER_IP}" == "${node}" ]; then
         continue
      fi
      # Check if node is already initializated - that means the cluster has already been bootstraped 
      if sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${node} "[ -e ${PXC_BOOTSTRAP_FLAG} ]" >/dev/null 2>&1; then
         BOOTSTRAPED=true
         break
      fi
   done
   
   if ${BOOTSTRAPED}; then
      echo "=> Seems like cluster has already been bootstraped, so I'm joining it ..."
      join-cluster.sh || exit 1
   else
      # If I could not detect any other container bootstraped I'm bootstraping it, but only if I'm the first one in PXC_NODES
      if [ "${MY_RANCHER_IP}" == `echo "${PXC_NODES}" | awk -F, '{print $1}'` ]; then
         bootstrap-pxc.sh || exit 1
      # Don't bootstrap the cluster, just join it - Needed for subsequent containers initialization
      else
         echo "=> Seems like cluster is being bootstraped by another container, so I'm joining it ..."
         join-cluster.sh || exit 1
      fi
   fi
else
   # If this container is already configured, just start it
   echo "=> I was already part of the cluster, starting PXC"
   /usr/bin/supervisord
fi
