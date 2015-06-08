#!/bin/bash

set -e

[ "$DEBUG" == "1" ] && set -x && set +e

echo "=> Notifying the cluster about myself"
for node in `echo "${PXC_NODES}" | sed "s/,/ /g"`; do
   # Skip myself
   if [ "${MY_RANCHER_IP}" == "${node}" ]; then
      continue
   fi
   if ! sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${node} "hostname" >/dev/null 2>&1; then
      continue
   fi
   echo "=> Notifying node $node about myself ..."
   sshpass -p ${PXC_ROOT_PASSWORD} ssh ${SSH_OPTS} ${SSH_USER}@${node} "change_pxc_nodes.sh \"${PXC_NODES}\""
done
touch ${PXC_CONF_FLAG}

echo "=> Starting PXC Cluster"
/usr/bin/supervisord