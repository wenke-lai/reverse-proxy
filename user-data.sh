#!/bin/bash

sleep 30
apt-get update -y

# create swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# disable auto update
sed -i 's/APT::Periodic::Update-Package-Lists "1"/APT::Periodic::Update-Package-Lists "0"/' /etc/apt/apt.conf.d/20auto-upgrades
apt-get remove -y unattended-upgrades
systemctl kill --kill-who=all apt-daily.service
systemctl stop apt-daily.timer
systemctl disable apt-daily.timer
systemctl stop apt-daily.service
systemctl disable apt-daily.service
systemctl stop apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.timer
systemctl stop apt-daily-upgrade.service
systemctl disable apt-daily-upgrade.service
systemctl daemon-reload
# systemctl list-timers  # debug

# system limits
echo -e "* soft nofile 65535\n* hard nofile 65535" >> /etc/security/limits.conf
echo -e "SystemMaxUse=100M" >> /etc/systemd/journald.conf
echo -e "SystemMaxFileSize=20M" >> /etc/systemd/journald.conf
systemctl restart systemd-journald.service

# setup docker
mkdir /etc/docker
echo -e "{\"log-opts\": {\"max-size\": \"50m\", \"max-file\": \"3\"}}" > /etc/docker/daemon.json
apt-get install -y docker.io net-tools iproute2
service docker restart

