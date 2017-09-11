#!/bin/bash

if [ -z "$1" ]; then  
  echo -e "\nERROR: Param engine label not specified\n"
fi

engine_label=$1

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" update
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade -y

echo debconf iptables-persistent/autosave_done select true | debconf-set-selections
echo debconf iptables-persistent/autosave_done seen true | debconf-set-selections

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y mc ntp software-properties-common apt-transport-https curl iptables-persistent netfilter-persistent

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
echo '{"labels": ["dc='${engine_label}'"]}' >> /etc/docker/daemon.json
service docker restart 

netfilter-persistent flush
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 2376 -j ACCEPT
iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
iptables -A INPUT -p udp --dport 7946 -j ACCEPT
iptables -A INPUT -p udp --dport 4789 -j ACCEPT
netfilter-persistent save

echo -e "\nClientAliveInterval 60\nTCPKeepAlive yes\nClientAliveCountMax 180\n" >> /etc/ssh/sshd_config
service sshd restart

sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" > /etc/sysctl.d/60-max_map_count.conf


