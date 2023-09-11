#!/bin/bash
set -e

function exit_badly() {
  echo $1
  exit 1
}

PASSWORD=""

[ -z "$PASSWORD" ] && exit_badly "PASSWORD is not specified!"

[[ $(id -u) -eq 0 ]] || exit_badly "Please run as root and try again."

apt update --fix-missing -y
apt full-upgrade -y
apt autoremove -y
apt install sudo vim -y
useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G sudo admin
chown admin:admin *
cp * /home/admin/
rm /home/admin/client_pre.sh
rm *
reboot