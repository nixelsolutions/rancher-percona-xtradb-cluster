#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_MULTICAST_ADDRESS}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_MULTICAST_ADDRESS" environment variable - Exiting..."
   exit 1
fi
if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_SST_PASSWORD" environment variable - Exiting..."
   exit 1
fi

echo "=> Configuring PXC cluster"
MY_RANCHER_IP=`echo ${RANCHER_IP} | awk -F\/ '{print $1}'`
perl -p -i -e "s/PXC_MULTICAST_ADDRESS/$PXC_MULTICAST_ADDRESS/g" ${PXC_CONF}
perl -p -i -e "s/PXC_SST_PASSWORD/$PXC_SST_PASSWORD/g" ${PXC_CONF}
perl -p -i -e "s/MY_RANCHER_IP/$MY_RANCHER_IP/g" ${PXC_CONF}
echo "PXC_MULTICAST_ADDRESS=${PXC_MULTICAST_ADDRESS}" > ${PXC_CONF_FLAG}
echo "PXC_SST_PASSWORD=${PXC_SST_PASSWORD}" >> ${PXC_CONF_FLAG}
chmod 600 ${PXC_CONF_FLAG}
chown -R mysql:mysql ${PXC_VOLUME}

echo "=> Starting PXC Cluster"
/usr/bin/supervisord
