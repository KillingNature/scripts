#!/bin/bash
set -x #Uncomment for debug
#CURRENTUSER=$(logname)
apt-get update
#apt-get upgrade
ufw allow 25,80,443,465,587,8080,60000:65535/tcp
apt install -y nginx
apt install -y php7.4-cli php7.4-fpm php7.4-curl php7.4-gd php7.4-mysql php7.4-mbstring zip unzip
systemctl enable nginx
rm /etc/nginx/sites-enabled/default
wget --no-check-certificate --content-disposition -P /etc/nginx/sites-enabled/ https://raw.githubusercontent.com/KillingNature/configs/main/default.conf
echo -e "\e[31mВведите полное имя домена:\e[0m"
read DOMAIN
mkdir /var/www/$DOMAIN
adduser $USER www-data
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R g+rw /var/www/$DOMAIN
echo '<?php phpinfo(); ?>' >> /var/www/$DOMAIN/index.php
apt-get install -y mariadb-server
systemctl enable mariadb
echo -e "\e[31mЗадайте пароль для для root на БД:\e[0m"
mysqladmin -u root password
apt-get install -y php-mysql
apt-get install -y phpmyadmin #Криво устанавливается
wget --no-check-certificate --content-disposition -P /etc/nginx/sites-enabled/ https://raw.githubusercontent.com/KillingNature/configs/main/phpmyadmin.conf
sed -i -e "s/#Name/php.$DOMAIN/g" /etc/nginx/sites-enabled/phpmyadmin.conf
my_ip=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}') #IP устройства
sed -i "1s/^/$my_ip $DOMAIN\n/" /etc/hosts
sed -i -e "s/#Name/$DOMAIN/g" /etc/nginx/sites-enabled/default.conf
systemctl reload nginx
apt-get install -y memcached php-memcached
systemctl enable memcached
systemctl restart php7.4-fpm
systemctl restart nginx

#Установка FTP
cp /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
apt-get install -y chrony
systemctl enable chrony
apt-get install -y proftpd
echo "Использовать стандартный диапазон портов?[y/N]"
read agree
case "$agree" in
    y|Y) break
        ;;
    n|N) 
    echo "Введите начало диапазона:"
    read PORT1
    echo "Введите конец диапазона:"
    read PORT2
    echo $PORT1 $PORT2
    sed -i -e "s/# PassivePorts.*49152 65534/PassivePorts                  $PORT1 $PORT2/g" /etc/proftpd/proftpd.conf
        
        ;;
    *) 
        break
        ;;
esac
ufw allow 20,21,$PORT1:$PORT2/tcp

echo "Разрешить использование IPv6?[y/N]"
read agree
case "$agree" in
    y|Y) STATUS=on
        ;;
    n|N) STATUS=off
        ;;
    *) STATUS=off
        ;;
esac
echo $STATUS
sed -i -e "s/UseIPv6.*on/UseIPv6                         $STATUS/g" /etc/proftpd/proftpd.conf
systemctl enable proftpd

echo "Использовать передечу данных через TLS?[y/N]"
read agree
case "$agree" in
    y|Y) 
    
    sed -i -e "s\#TLSEngine\TLSEngine\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSLog\TLSLog\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSProtocol\TLSProtocol\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSRSACertificateFile\TLSRSACertificateFile\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSRSACertificateKeyFile\TLSRSACertificateKeyFile\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSOptions\TLSOptions\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSVerifyClient\TLSVerifyClient\g" /etc/proftpd/tls.conf
    sed -i -e "s\#TLSRequired\TLSRequired\g" /etc/proftpd/tls.conf
    echo "Требовать от клиента обязательное TLS соединение?[y/N]"
    read agree
    case "$agree" in
        y|Y) STATUS=on
            ;;
        n|N) STATUS=off
            ;;
        *) STATUS=off
            ;;
    esac
    sed -i -e "s\#TLSRequired.*on \TLSRequired                             $STATUS\g" /etc/proftpd/tls.conf
    openssl req -x509 -nodes -newkey rsa:1024 -keyout /etc/ssl/private/proftpd.key -out /etc/ssl/certs/proftpd.crt -subj "/C=RU/ST=SPb/L=SPb/O=Global Security/OU=IT Department/CN=ftp.server.test/CN=ftp"    
        ;;
    n|N) break
        ;;
    *) break
        ;;
esac
echo "\e[31mУкажите имя FTP пользователя:\e[0m"
read USERNAME

#Создание пользователя
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=$USERNAME.local --uid=33 --gid=33 --home=/var/www/$DOMAIN --shell=/usr/sbin/nologin
sed -i -e "s\#DefaultRoot\DefaultRoot\g" /etc/proftpd/proftpd.conf

echo "RequireValidShell off
AuthUserFile /etc/proftpd/ftpd.passwd
AuthPAM off
LoadModule mod_auth_file.c
AuthOrder mod_auth_file.c" > /etc/proftpd/conf.d/virtual_file.conf
systemctl restart proftpd

echo -e "\e[31mНеобходимо добавить $my_ip $DOMAIN и $my_ip php.$DOMAIN в файл hosts\e[0m"