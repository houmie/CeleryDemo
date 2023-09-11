#!/bin/bash
set -e

MAIN_IP=""
REDIS_PASSWORD="dmzRAvTIfQkqVM/u4Ck2zkEeAuHArvpAYIKRwgkwnTclKgQ/zjRYvgPacFR69JOp6o1F1ZPxvE5ylBEO%"
REDIS_PORT=6939

exit_badly() {
  echo "$1"
  exit 1
}

OS=$(cat /etc/os-release)
[[ $OS != *"bookworm"* ]] && exit_badly "Debian 12 must be installed."
[ "$(id -u)" -eq 0 ] && exit_badly "Please run client_pre.sh first, then 'sudo su admin' to run as admin user. Then cd /home/admin/ and run client.sh"

export DEBIAN_FRONTEND=noninteractive
sudo -E apt install -y wget gnupg2 software-properties-common libtalloc-dev apt-transport-https build-essential make moreutils # foundation
sudo -E apt install -y net-tools postfix mailutils git tmux htop redis redis-tools libsasl2-modules vim bash-completion liblzma-dev # tools
sudo -E apt install -y libelf-dev linux-headers-$(uname -r) pkg-config
sudo -E apt install -y zlib1g-dev libbz2-dev libreadline-dev libssl-dev libsqlite3-dev libffi-dev libpq-dev # needed for pyenv

echo
echo "--- Resolv DNS setup ---"
echo
sudo rm -r /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
sudo chattr +i /etc/resolv.conf

echo
echo "--- Configuring Celery ---"
echo
sudo useradd -m --system -s /bin/bash celery
sudo usermod -a -G admin celery
echo "mkdir /var/run/celery/
chown celery:celery /var/run/celery/
" | sudo tee /root/startup.sh >/dev/null
sudo mkdir /etc/celery/
echo "CELERY_APP=\"notify.my_celery:app\"
CELERYD_NODES=\"worker\"
CELERYD_OPTS=\"--without-mingle --without-gossip\"
CELERY_BIN=\"/home/admin/.pyenv/versions/venv/bin/celery\"
CELERYD_PID_FILE=\"/var/run/celery/%n.pid\"
CELERYD_LOG_FILE=\"/var/log/celery/%n%I.log\"
CELERYD_LOG_LEVEL=\"INFO\"
CELERYBEAT_PID_FILE=\"/var/run/celery/beat.pid\"
CELERYBEAT_LOG_FILE=\"/var/log/celery/beat.log\"
" | sudo tee /etc/celery/celery >/dev/null
sudo chown -R celery:celery /etc/celery/
sudo mkdir /var/run/celery/
sudo mkdir /var/log/celery/
sudo chown celery:celery /var/run/celery/
sudo chown celery:celery /var/log/celery/
echo "[Unit]
Description=Celery Service
After=network.target

[Service]
Type=forking
User=celery
Group=celery
EnvironmentFile=/etc/celery/celery
WorkingDirectory=/home/admin/CeleryDemo/app/
ExecStart=/bin/sh -c '\${CELERY_BIN} -A \$CELERY_APP multi start \$CELERYD_NODES --pidfile=\${CELERYD_PID_FILE} --logfile=\${CELERYD_LOG_FILE} --loglevel=\"\${CELERYD_LOG_LEVEL}\" \$CELERYD_OPTS'
ExecStop=/bin/sh -c '\${CELERY_BIN} multi stopwait \$CELERYD_NODES --pidfile=\${CELERYD_PID_FILE} --logfile=\${CELERYD_LOG_FILE}'
ExecReload=/bin/sh -c '\${CELERY_BIN} -A \$CELERY_APP multi restart \$CELERYD_NODES --pidfile=\${CELERYD_PID_FILE} --logfile=\${CELERYD_LOG_FILE} --loglevel=\"\${CELERYD_LOG_LEVEL}\" \$CELERYD_OPTS'
Restart=always

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/celery.service >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable celery.service
echo "[Unit]
Description=Celery Beat Service
After=network.target

[Service]
Type=simple
User=celery
Group=celery
EnvironmentFile=/etc/celery/celery
WorkingDirectory=/home/admin/CeleryDemo/app/
ExecStart=/bin/sh -c '\${CELERY_BIN} -A \${CELERY_APP} beat --pidfile=\${CELERYBEAT_PID_FILE} --logfile=\${CELERYBEAT_LOG_FILE} --loglevel=\${CELERYD_LOG_LEVEL} --schedule=/home/celery/celerybeat-schedule'
Restart=always

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/celerybeat.service >/dev/null
sudo systemctl daemon-reload
sudo systemctl enable celerybeat.service

echo
echo "--- Installing Python ---"
echo
git clone -b v2.3.22 https://github.com/yyuu/pyenv.git ~/.pyenv
git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
sed -i '1 i\export PYENV_ROOT="$HOME/.pyenv"' ~/.profile
sed -i '2 i\export PATH="$PYENV_ROOT/bin:$PATH"' ~/.profile
sed -i '3 i\eval "$(pyenv init --path)"' ~/.profile
echo 'export PYTHONPATH=:"$HOME/CeleryDemo/app"' >>~/.profile
sed -i '1 i\export PATH="/home/admin/.pyenv/bin:$PATH"' ~/.bashrc
sed -i '2 i\eval "$(pyenv init -)"' ~/.bashrc
sed -i '3 i\eval "$(pyenv virtualenv-init -)"' ~/.bashrc
source ~/.profile
pyenv install 3.11.4
pyenv virtualenv 3.11.4 venv
pyenv activate venv

cd ~
git clone https://github.com/houmie/CeleryDemo.git
cd CeleryDemo
pip install -r requirements.txt

echo "REDIS_IP=\"${MAIN_IP}\"
REDIS_PASSWORD=\"${REDIS_PASSWORD}\"
REDIS_PORT=${REDIS_PORT}
REDIS_DB=0
" >~/CeleryDemo/app/.env

sudo systemctl start celery.service
sudo systemctl start celerybeat.service

sudo crontab -l | {
cat
echo "@reboot bash ~/startup.sh"
  } | sudo crontab -