#!/bin/bash
set -e

REDIS_PASSWORD="dmzRAvTIfQkqVM/u4Ck2zkEeAuHArvpAYIKRwgkwnTclKgQ/zjRYvgPacFR69JOp6o1F1ZPxvE5ylBEO%"
REDIS_PORT=6939

export DEBIAN_FRONTEND=noninteractive

apt update --fix-missing -y
apt full-upgrade -y
apt autoremove -y
apt install -y sudo redis


echo
echo "--- Resolv DNS setup ---"
echo
sudo rm -r /etc/resolv.conf
echo "nameserver 1.1.1.1
nameserver 2606:4700:4700::1111" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf

echo
echo "--- Redis ---"
echo
sudo sed -i "s=# requirepass foobared=requirepass ${REDIS_PASSWORD}=" /etc/redis/redis.conf
sudo sed -i "s/bind 127.0.0.1 -::1/# bind 127.0.0.1 -::1/" /etc/redis/redis.conf
sudo sed -i "s/port 6379/port ${REDIS_PORT}/" /etc/redis/redis.conf
sudo systemctl restart redis

sudo systemctl status redis