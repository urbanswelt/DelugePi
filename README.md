DelugePi
===========

Shell script for installing and updating Deluge Torrent on the Raspberry Pi. The script either performs a new installation of the newest stable Deluge release or, if already installed, performs an upgrade to the newest release.

This script was tested on the Raspbian distribution from 2012-12-16-wheezy-raspbian with Deluge Torrent 1.3.5 stable.


Make sure that Git and Dialog is installed:

```shell
sudo apt-get update
sudo apt-get install -y git dialog
```

Then you can download the latest DelugePi setup script with

```shell
cd
git clone git://github.com/petrockblog/OwncloudPie.git
```

The script is executed with 

```shell
cd DelugePi
chmod +x deluge_setup.sh
sudo ./deluge_setup.sh
```

For more information visit the blog at http://urbanswelt.de or the repository at https://github.com/urbanswelt/DelugePi .

