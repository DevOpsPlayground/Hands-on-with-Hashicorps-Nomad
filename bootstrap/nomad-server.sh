#!/bin/sh
sudo yum update -y
yum install -y docker
usermod -a -G docker ec2-user
service docker start
chkconfig docker on

curl -O https://releases.hashicorp.com/nomad/0.6.3/nomad_0.6.3_linux_amd64.zip
unzip nomad_0.6.3_linux_amd64.zip
rm -f nomad_0.6.3_linux_amd64.zip
sudo mv nomad /usr/local/bin

sudo sed -i -e "s|/sbin\:/bin\:/usr/sbin\:/usr/bin|/sbin\:/bin\:/usr/sbin\:/usr/bin\:/usr/local/bin|g" /etc/sudoers

aws s3 cp s3://devops-playground-configurations/configs/server.hcl /home/ec2-user
aws s3 cp s3://devops-playground-configurations/jobs/webapp.nomad /home/ec2-user
aws s3 cp s3://devops-playground-configurations/jobs/cluster.nomad /home/ec2-user

sudo chmod 777 /home/ec2-user/server.hcl
sudo chmod 777 /home/ec2-user/webapp.nomad
sudo chmod 777 /home/ec2-user/cluster.nomad

sudo sed -i "s/SERVER_INTERNAL_IP/$(ifconfig eth0 | awk '/inet addr/ { print $2}' | sed 's#addr:##g')/g" /home/ec2-user/server.hcl

