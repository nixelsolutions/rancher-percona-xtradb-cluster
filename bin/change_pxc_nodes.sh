#!/bin/bash

set -e

PXC_NODES=$1
if [ "${PXC_NODES}" == "**ChangeMe**" ] || [ -z ${PXC_NODES} ]; then
   echo "ERROR: You did not specify nodes to join PXC cluster, please enter PXC nodes as an argument."
   echo "You may specify more than one node separated by a comma, for example: $0 X.X.X.X,Y.Y.Y.Y"
   echo "Exiting..."
   exit 1
fi

perl -p -i -e "s/wsrep_cluster_address = gcomm:\/\//wsrep_cluster_address = gcomm:\/\/$PXC_NODES" ${PXC_CONF}
