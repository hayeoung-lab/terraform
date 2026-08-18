#!/bin/bash
exec > /var/log/web.log 2>&1
echo "[ START ]"
yum -y install httpd php php-mysqlnd
systemctl enable --now httpd

cat > /var/www/html/index.php <<PHPEOF
<h1>WEB/WAS Server</h1>
<p>DB address: ${db_address}</p>
<p>DB port: ${db_port}</p>
PHPEOF

echo "[ END ]"
