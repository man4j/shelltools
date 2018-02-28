#!/bin/bash

filename=$1
ADVERTISE_ADDR=$2
DATA_PATH_ADDR=$3

if [ ! -z "${filename}" ]; then
  echo >&2 "Config file not specified"
  exit -1
fi

if [ ! -z "${ADVERTISE_ADDR}" ]; then
  echo >&2 "ADVERTISE_ADDR not specified"
  exit -1
fi

: ${DATA_PATH_ADDR="${ADVERTISE_ADDR}"}

SSH="$DEBUG ssh $SSH_KEY_OPT -kTax -q -o StrictHostKeyChecking=no"
i=0
idx=0
while IFS= read -r line || [ -n "$line" ]
do
    if [ $i == 0 ]
    then
        # NODE_COUNT is the total number of nodes that in the swarm cluster
        if [[ $line =~ ^NODE_COUNT=-?[0-9]+$ ]]
        then
            NODE_COUNT="${line#*=}"
            echo "NODE_COUNT=$NODE_COUNT"
        else
            echo "Invalid value for NODE_COUNT:$line"
            exit 1
        fi
    fi
    if [ $i == 1 ]
    then
        # MGR_COUNT is the total number of manager nodes in the swarm cluster
        if [[ $line =~ ^MGR_COUNT=-?[0-9]+$ ]]
        then
            MGR_COUNT="${line#*=}"
            echo "MGR_COUNT=$MGR_COUNT"
        else
            echo "Invalid value for MGR_COUNT:$line"
            exit 1
        fi
    fi

    if [ "$i" -gt "1" ]
    then
        # Read IP address in to array
        # In the configuration file, the first $MGR_COUNT line of IP address
        # will be the IP address of swarm manager node
        IP_ADDRESS[idx]=$line
        idx=$((idx+1))
    fi
    i=$((i+1))
done <$1

IP_COUNT=$idx

echo "IP_COUNT $IP_COUNT"

if [ "$MGR_COUNT" -gt "$NODE_COUNT" ]
then
    echo "Total number of nodes cannot be smaller than the total number of manager nodes"
    exit 1
fi

if [ $((MGR_COUNT%2)) -eq 0 ]
then
    echo "Total number of manager nodes in the swarm cluster cannot be a even number"
    exit 1
fi

if [ "$MGR_COUNT" -gt "7" ]
then
    echo "Total number of manager in the swarm cluster is too big"
    exit 1
fi

if [ $NODE_COUNT != $IP_COUNT ]
then
    echo "Total number of nodes does not match the number of IP addresses"
    exit 1
fi

#========================================================================================
echo "Docker Setup Start"

for i in `seq 0 $((NODE_COUNT-1))`
do
echo "install docker engine on node with IP ${IP_ADDRESS[$i]}"

$SSH root@${IP_ADDRESS[$i]} 'bash -s' <<-EODOCKER
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
EODOCKER

done

echo "Docker Setup Complete"

#========================================================================================
echo "Swarm Cluster Setup Start"

echo "======> Initializing first swarm manager ..."
$SSH root@${IP_ADDRESS[0]}  "docker swarm init --advertise-addr ${ADVERTISE_ADDR} --data-path-addr ${DATA_PATH_ADDR}"

# Fetch Tokens
ManagerToken=`$SSH root@${IP_ADDRESS[0]} docker swarm join-token manager | grep token`
WorkerToken=`$SSH root@${IP_ADDRESS[0]} docker swarm join-token worker | grep token`

echo "Manager Token: ${ManagerToken}"
echo "Workder Token: ${WorkerToken}"

# Add remaining manager to swarm
echo "======> Add other manager nodes"
for i in `seq 1 $((MGR_COUNT-1))`
do
    echo "node with IP ${IP_ADDRESS[$i]} joins swarm as a Manager"
    $SSH root@${IP_ADDRESS[$i]} ${ManagerToken}
done

# Add worker to swarm
echo "======> Add worker nodes"
for i in `seq $((MGR_COUNT)) $((NODE_COUNT-1))`
do
     echo "node with IP ${IP_ADDRESS[$i]} joins swarm as a Worker"
     $SSH root@${IP_ADDRESS[$i]} ${WorkerToken}
done

# list nodes in swarm cluster
$SSH root@${IP_ADDRESS[0]} "docker node ls"

echo "Swarm Cluster Setup Complete"

#========================================================================================
echo "Imagenarium Setup Start"

$SSH root@${IP_ADDRESS[0]} 'bash -s' <<-EODOCKER
docker network create --driver overlay --attachable clustercontrol-net
docker service create --detach=false -p 5555:8080 --name clustercontrol \
--network clustercontrol-net \
--mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
--mount "type=bind,source=/root,target=/root" \
--constraint "node.role == manager" \
imagenarium/clustercontrol:0.9.0
EODOCKER

echo "Imagenarium Setup Complete"