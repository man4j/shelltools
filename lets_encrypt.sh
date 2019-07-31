#!/bin.bash

echo -e "dns_linode_key = KEY \n" > creds.ini
echo "dns_linode_version = 4" >> creds.ini

docker run -it --rm -v ${PWD}:/mnt certbot/dns-linode certonly -n \
--email man4j@ya.ru \
--agree-tos \
--dns-linode \
--dns-linode-credentials /mnt/creds.ini \
--config-dir /mnt \
-d markingcodes.ru
