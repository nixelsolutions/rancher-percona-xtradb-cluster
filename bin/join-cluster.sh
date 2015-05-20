#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_NODES}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_NODES_ADDRESS" environment variable - Exiting..."
   exit 1
fi
if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" ]; then
   echo "ERROR: You did not specify "PXC_SST_PASSWORD" environment variable - Exiting..."
   exit 1
fi

PXC_NODES=`echo ${PXC_NODES} | sed "s/ //g"`

echo "=> Configuring PXC cluster"
echo "root:${PXC_ROOT_PASSWORD}" | chpasswd
sleep 2
MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
for node in `echo ${PXC_NODES} | sed "s/,/ /"g`; do
   echo "=> Updating PXC cluster to add my IP to the cluster"
   echo "=> Trying to update configuration on node $node ..."
   sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} root@$node "change_pxc_nodes.sh \"${PXC_NODES},${MY_RANCHER_IP}\""
done
change_pxc_nodes.sh "${PXC_NODES},${MY_RANCHER_IP}"
perl -p -i -e "s/PXC_SST_PASSWORD/$PXC_SST_PASSWORD/g" ${PXC_CONF}
perl -p -i -e "s/MY_RANCHER_IP/$MY_RANCHER_IP/g" ${PXC_CONF}
echo "PXC_NODES=\"${PXC_NODES},${MY_RANCHER_IP}\"" > ${PXC_CONF_FLAG}
echo "PXC_SST_PASSWORD=${PXC_SST_PASSWORD}" >> ${PXC_CONF_FLAG}
echo "PXC_ROOT_PASSWORD=${PXC_ROOT_PASSWORD}" >> ${PXC_CONF_FLAG}
chmod 600 ${PXC_CONF_FLAG}
chown -R mysql:mysql ${PXC_VOLUME}

echo "=> Starting PXC Cluster"
/usr/bin/supervisord
