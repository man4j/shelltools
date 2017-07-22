#!/bin/bash

mkdir /home/bench/
cd /home/bench/
echo "Testing write speed..."
dd if=/dev/zero of=diskbench bs=1M count=1024 conv=fdatasync
echo 3 | tee /proc/sys/vm/drop_caches
echo "Testing reading without cache..."
dd if=diskbench of=/dev/null bs=1M count=1024
echo "Testing reading with cache..."
dd if=diskbench of=/dev/null bs=1M count=1024
rm -f diskbench
echo "Testing cpu..."
dd if=/dev/zero bs=1M count=1024 | md5sum
echo "CPU info:"
lscpu
echo "Testing network speed..."
wget -O /dev/null http://cachefly.cachefly.net/100mb.test
