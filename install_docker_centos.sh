#!/bin/bash

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install yum-utils firewalld device-mapper-persistent-data lvm2 ntp docker-ce

systemctl start firewalld && systemctl enable firewalld
systemctl start docker && systemctl enable docker
systemctl start ntpd && systemctl enable ntpd

firewall-cmd --add-port=2376/tcp --permanent
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=7946/tcp --permanent
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=4789/udp --permanent
firewall-cmd --reload

docker plugin install --grant-all-permissions --alias vsphere vmware/vsphere-storage-for-docker:latest
docker plugin install --grant-all-permissions --alias weave weaveworks/net-plugin:latest_release

systemctl restart docker
