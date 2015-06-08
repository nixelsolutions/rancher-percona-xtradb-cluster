#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

source ${PXC_CONF_FLAG}

echo "=> Notifying the cluster about myself"
for node in `echo "${PXC_NODES}" | sed "s/,//g"`; do
   # Skip myself
   if [ "${MY_RANCHER_IP}" == "${node}" ]; then
      continue
   fi
   echo "=> Notifying node $node about myself ..."
   sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} root@$node "change_pxc_nodes.sh \"${PXC_NODES}\""
done
touch ${PXC_CONF_FLAG}
chmod 600 ${PXC_CONF_FLAG}

echo "=> Starting PXC Cluster"
/usr/bin/supervisord