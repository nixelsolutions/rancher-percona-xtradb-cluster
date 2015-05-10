#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_BOOTSTRAP}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_BOOTSTRAP" environment variable - Exiting..."
   exit 1
fi

# If this container is not configured, just configure it
if [ ! -e ${PXC_CONF_FLAG} ]; then
   # Bootstrap the cluster - Needed for first container initialization
   if [ `echo "${PXC_BOOTSTRAP}" | tr '[:lower:]' '[:upper:]'` == "YES" ]; then
      bootstrap-pxc.sh || exit 1
   # Don't bootstrap the cluster, just join it - Needed for subsequent containers initialization
   elif [ `echo "${PXC_BOOTSTRAP}" | tr '[:lower:]' '[:upper:]'` == "NO" ]; then
      join-cluster.sh || exit 1
   else 
      echo "ERROR: you did not specify a valid value for "PXC_BOOTSTRAP" environment variable - Exiting..."
      exit 1
   fi
else
   # If this container is already configured, just start it
   source ${PXC_CONF_FLAG}
   echo "==========================================="
   echo "When you need to join other nixel/rancher-percona-xtradb-cluster containers to this PXC, you will need the following ENVIRONMENT VARIABLES:"
   echo "PXC_BOOTSTRAP=NO"
   echo "PXC_NODES=${PXC_NODES}"
   echo "PXC_SST_PASSWORD=${PXC_SST_PASSWORD}"
   echo "PXC_ROOT_PASSWORD=${PXC_ROOT_PASSWORD}"
   echo "===========================================" 
   fi
   echo "=> Starting PXC Cluster"
   /usr/bin/supervisord
fi
