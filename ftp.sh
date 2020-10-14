#!/bin/bash
#set -x #Uncomment for debug
cp /usr/share/zoneinfo/Asia/Yekaterinburg /etc/localtime
apt-get install chrony
systemctl enable chrony
apt-get install proftpd
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
echo "Укажите имя пользователя:"
read USERNAME

#Спросить про uid и gid
ftpasswd --passwd --file=/etc/proftpd/ftpd.passwd --name=$USERNAME  --uid=33 --gid=33 --home=/var/tmp --shell=/usr/sbin/nologin
sed -i -e "s\#DefaultRoot\DefaultRoot\g" /etc/proftpd/proftpd.conf

echo "RequireValidShell off
AuthUserFile /etc/proftpd/ftpd.passwd
AuthPAM off
LoadModule mod_auth_file.c
AuthOrder mod_auth_file.c" > /etc/proftpd/conf.d/virtual_file.conf
systemctl restart proftpd
