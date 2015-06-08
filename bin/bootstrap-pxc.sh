#!/bin/bash

set -e
set +H

[ "$DEBUG" == "1" ] && set -x && set +e

# Bootstrap the cluster
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
touch ${PXC_CONF_FLAG}

echo "=> Starting PXC Cluster"
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord_bootstrap.conf