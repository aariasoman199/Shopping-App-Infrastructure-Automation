#!/bin/bash

echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
echo "LANG=en_US.utf-8" >> /etc/environment
echo "LC_ALL=en_US.utf-8" >> /etc/environment
service sshd restart


yum install httpd php -y


systemctl restart httpd.service php-fpm.service
systemctl enable httpd.service php-fpm.service
