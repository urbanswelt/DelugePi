#!/bin/bash
# deluge-1.3.5 - install latest stable Deluge Version on Raspberry PI Server
# latest images 2012-12-16-wheezy-raspbian from http://www.raspberrypi.org/downloads
#
# Last updated 2012-12-27
# init
sudo adduser --disabled-password --system --home /var/lib/deluge --gecos "WebBased Deluge Server" --group deluge
sudo mkdir -p /var/log/deluge/daemon
sudo mkdir /var/log/deluge/web
sudo chmod -R 755 /var/log/deluge
sudo chown -R deluge /var/log/deluge