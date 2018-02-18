#!/bin/bash

if [ -z "$1" ]; then..
  echo -e "\nERROR: Param dc label not specified\n"
fi

dc_label=$1

yum -y install yum-utils device-mapper-persistent-data lvm2 ntp
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce
systemctl start docker && systemctl enable docker
echo '{"labels": ["dc='${dc_label}'"]}' >> /etc/docker/daemon.json
systemctl restart docker

firewall-cmd --add-port=2376/tcp --permanent
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=7946/tcp --permanent
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=4789/udp --permanent
firewall-cmd --reload

docker plugin install --grant-all-permissions --alias vsphere vmware/vsphere-storage-for-docker:latest
docker plugin install --alias weave weaveworks/net-plugin:latest_release

echo -e "\nClientAliveInterval 60\nTCPKeepAlive yes\nClientAliveCountMax 180\n" >> /etc/ssh/sshd_config
service sshd restart

systemctl enable ntpd
systemctl start ntpd
