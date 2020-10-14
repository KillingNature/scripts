#!/bin/bash
set -x #Uncomment for debug
CURRENTUSER=$(logname)
apt-get update && apt-get upgrade -y
apt update
ufw allow 25,80,443,465,587,8080,60000:65535/tcp
apt install -y nginx
apt install -y php7.4-cli php7.4-fpm php7.4-curl php7.4-gd php7.4-mysql php7.4-mbstring zip unzip
systemctl enable nginx
rm /etc/nginx/sites-enabled/default
wget --no-check-certificate --content-disposition -P /etc/nginx/sites-enabled/ https://raw.githubusercontent.com/KillingNature/configs/main/default.conf
adduser $USER www-data
chown -R www-data:www-data /var/www/html
chmod -R g+rw /var/www/html
echo '<?php phpinfo(); ?>' >> /var/www/html/index.php
apt-get install -y mariadb-server
systemctl enable mariadb
echo -e "\e[31mЗадайте пароль для для root на БД:\e[0m"
mysqladmin -u root password
apt-get install -y php-mysql
apt-get install -y phpmyadmin #Криво устанавливается
wget --no-check-certificate --content-disposition -P /etc/nginx/sites-enabled/ https://raw.githubusercontent.com/KillingNature/configs/main/phpmyadmin.conf
echo -e "\e[31mВведите полное имя домена:\e[0m"
read DOMAIN
sed -i -e "s/phpmyadmin.dmosk.local/$DOMAIN/g" /etc/nginx/sites-enabled/phpmyadmin.conf
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
sed -i "1s/^/$my_ip $DOMAIN\n/" /etc/hosts
sed -i -e "s/#Name/$DOMAIN/g" /etc/nginx/sites-enabled/default.conf
systemctl reload nginx
apt-get install -y memcached php-memcached
systemctl enable memcached
systemctl restart php7.4-fpm
systemctl restart nginx