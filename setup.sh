#!/bin/sh
# Auto FTP Installed by Abhishek Deb

FTP_CONF=/etc/vsftpd.conf
FTP_USERS=/etc/vsftpd.userlist
pasv_min_port=40000
pasv_max_port=50000


apt update -y
apt upgrade -y
apt clean

apt install ufw vsftpd curl -y
systemctl start vsftpd
systemctl enable vsftpd

ufw enable

ufw allow 20/tcp

ufw allow 21/tcp

echo "Configuring FTP ... "
PUBLIC_IP=${1:-$(curl checkip.amazonaws.com)}

echo "PUBLIC_IP: $PUBLIC_IP"

cp $FTP_CONF $FTP_CONF.bak
cat >$FTP_CONF <<EOL
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
ftpd_banner=Welcome to YOYO FTP service.
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
ssl_enable=NO
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH

force_dot_files=YES
pasv_enable=YES
pasv_min_port=${pasv_min_port}
pasv_max_port=${pasv_max_port}
port_enable=YES
pasv_address=${PUBLIC_IP}

user_sub_token=$USER
local_root=/home/$USER/ftp

userlist_enable=YES
userlist_file=$FTP_USERS
userlist_deny=NO
EOL


systemctl restart vsftpd.service

echo "FTP_CONF: $FTP_CONF"
echo "FTP_USERS: $FTP_USERS"
echo "PUBLIC_IP: $PUBLIC_IP"