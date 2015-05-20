#!/bin/bash

set -e
set +H

[ "$DEBUG" == "1" ] && set -x && set +e

if [ "${PXC_SST_PASSWORD}" == "**ChangeMe**" ]; then
   PXC_SST_PASSWORD=`pwgen -s 20 1`
fi

if [ "${PXC_ROOT_PASSWORD}" == "**ChangeMe**" ]; then
   PXC_ROOT_PASSWORD=`pwgen -s 20 1`
fi

echo "=> Configuring PXC cluster"
echo "root:${PXC_ROOT_PASSWORD}" | chpasswd
sleep 2
MY_RANCHER_IP=`ip addr | grep inet | grep 10.42 | tail -1 | awk '{print $2}' | awk -F\/ '{print $1}'`
change_pxc_nodes.sh "${MY_RANCHER_IP}"
perl -p -i -e "s/PXC_SST_PASSWORD/${PXC_SST_PASSWORD}/g" ${PXC_CONF}
perl -p -i -e "s/MY_RANCHER_IP/${MY_RANCHER_IP}/g" ${PXC_CONF}
echo "PXC_NODES=\"${MY_RANCHER_IP}\"" > ${PXC_CONF_FLAG}
echo "PXC_SST_PASSWORD=${PXC_SST_PASSWORD}" >> ${PXC_CONF_FLAG}
echo "PXC_ROOT_PASSWORD=${PXC_ROOT_PASSWORD}" >> ${PXC_CONF_FLAG}
chmod 600 ${PXC_CONF_FLAG}
chown -R mysql:mysql ${PXC_VOLUME}

echo "==========================================="
echo "When you need to join other nixel/rancher-percona-xtradb-cluster containers to this PXC, you will need the following ENVIRONMENT VARIABLES:"
echo "PXC_BOOTSTRAP=NO"
echo "PXC_NODES=${MY_RANCHER_IP}"
echo "PXC_SST_PASSWORD=${PXC_SST_PASSWORD}"
echo "PXC_ROOT_PASSWORD=${PXC_ROOT_PASSWORD}"
echo "==========================================="

# Bootstrap the cluster
if [ `echo "${PXC_BOOTSTRAP}" | tr '[:lower:]' '[:upper:]'` == "YES" ]; then
   echo "=> Bootstrapping PXC cluster"
   mysql_install_db --datadir=${PXC_VOLUME} >/dev/null 2>&1
   echo "CREATE USER 'root'@'%' IDENTIFIED BY '${PXC_ROOT_PASSWORD}';" > /tmp/init.sql
   echo "GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;" >> /tmp/init.sql
   echo "UPDATE mysql.user set Password=PASSWORD('${PXC_ROOT_PASSWORD}') where user='root';" >> /tmp/init.sql
   echo "DELETE FROM mysql.user WHERE User='';" >> /tmp/init.sql
   echo "DROP DATABASE test;" >> /tmp/init.sql
   echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >> /tmp/init.sql
   echo "CREATE USER 'sstuser'@'%' IDENTIFIED BY '${PXC_SST_PASSWORD}';" >> /tmp/init.sql
   echo "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sstuser'@'%';" >> /tmp/init.sql
   echo "GRANT PROCESS ON *.* TO 'clustercheckuser'@'localhost' IDENTIFIED BY 'clustercheckpassword!';" >> /tmp/init.sql
   echo "FLUSH PRIVILEGES;" >> /tmp/init.sql
   /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord_bootstrap.conf
fi
