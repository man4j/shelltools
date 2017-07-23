#!/bin/bash

if [ -z "$1" ]; then  
  echo -e "\nERROR: Param engine label not specified\n"
fi

engine_label=$1

apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y && \
apt-get install -y mc ntp software-properties-common apt-transport-https curl iptables-persistent netfilter-persistent && \
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
apt-key fingerprint 0EBFCD88 && \
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
apt-get update && \
apt-get install -y docker-ce && \
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
echo '{"labels": ["dc='${engine_label}'"]}' >> /etc/docker/daemon.json && \
service docker restart && \
\
echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config && \
echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config && \
echo "ClientAliveCountMax 180" >> /etc/ssh/sshd_config && \
service sshd restart

