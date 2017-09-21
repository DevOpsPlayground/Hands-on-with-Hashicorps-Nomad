#!/bin/sh
sudo yum update -y
yum install -y docker
usermod -a -G docker ec2-user
service docker start
chkconfig docker on

curl -O https://releases.hashicorp.com/nomad/0.6.3/nomad_0.6.3_linux_amd64.zip
unzip nomad_0.6.3_linux_amd64.zip
rm -f nomad_0.6.3_linux_amd64.zip
mv nomad /usr/local/bin

sudo sed -i -e "s|/sbin\:/bin\:/usr/sbin\:/usr/bin|/sbin\:/bin\:/usr/sbin\:/usr/bin\:/usr/local/bin|g" /etc/sudoers