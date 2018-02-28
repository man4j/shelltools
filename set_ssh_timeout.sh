#!/bin/bash

echo -e "\nClientAliveInterval 60\nTCPKeepAlive yes\nClientAliveCountMax 180\n" >> /etc/ssh/sshd_config
service sshd restart