#!/bin/bash

if [ -z "$1" ]; then  
  echo -e "\nERROR: Param engine label not specified\n"
fi

engine_label=$1

apt-get update && \
apt-get upgrade -y && \
apt-get dist-upgrade -y && \
\
apt-get install -y mc && \
apt-get install -y ntp && \
\
apt-get install -y ca-certificates && \
apt-get install -y software-properties-common && \
apt-get install -y apt-transport-https && \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main' && \
apt-get update && \
apt-get install -y docker-engine && \
\
apt-get install -y netfilter-persistent && \
netfilter-persistent flush && \
iptables -A INPUT -p tcp --dport 22 -j ACCEPT && \
iptables -A INPUT -p tcp --dport 2376 -j ACCEPT && \
iptables -A INPUT -p tcp --dport 2377 -j ACCEPT && \
iptables -A INPUT -p tcp --dport 7946 -j ACCEPT && \
iptables -A INPUT -p udp --dport 7946 -j ACCEPT && \
iptables -A INPUT -p udp --dport 4789 -j ACCEPT && \
netfilter-persistent save && \
\
echo 'export PS1="${debian_chroot:+($debian_chroot)}\u@\H:\w# "' >> ~/.bashrc && \
PS1="${debian_chroot:+($debian_chroot)}\u@\H:\w# " && \
\
echo '{"labels": ["dc=${engine_label}"]}' >> /etc/docker/daemon.json && \
service docker restart && \
\
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config && \
echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config && \
echo "ClientAliveCountMax 180" >> /etc/ssh/sshd_config && \
service sshd restart

