#!/bin/bash
# deluge-1.3.stable - install latest stable Deluge Version on Raspberry PI Server
# latest images 2012-12-16-wheezy-raspbian from http://www.raspberrypi.org/downloads
#
# Last updated 2012-12-27
# init

function checkNeededPackages()
{
    doexit=0
    type -P git &>/dev/null && echo "Found git command." || { echo "Did not find git. Try 'sudo apt-get install -y git' first."; doexit=1; }
    type -P dialog &>/dev/null && echo "Found dialog command." || { echo "Did not find dialog. Try 'sudo apt-get install -y dialog' first."; doexit=1; }
    if [[ doexit -eq 1 ]]; then
        exit 1
    fi
}

function writeDelugeDaemon1()
{
cat > /etc/default/deluge-daemon <<'Endofmessage'
# Configuration for /etc/init.d/deluge-daemon
# The init.d script will only run if this variable non-empty.
DELUGED_USER="deluge"

# Should we run at startup?
RUN_AT_STARTUP="YES"
Endofmessage
}

function writeDelugeDaemon2()
{
cat > /etc/init.d/deluge-daemon <<'Endofmessage'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          deluge-daemon
# Required-Start:    $local_fs $remote_fs
# Required-Stop:     $local_fs $remote_fs
# Should-Start:      $network
# Should-Stop:       $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Daemonized version of deluge and webui.
# Description:       Starts the deluge daemon with the user specified in
#                    /etc/default/deluge-daemon.
### END INIT INFO

# Author: Adolfo R. Brandes 

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DESC="Deluge Daemon"
NAME1="deluged"
NAME2="deluge"
DAEMON1=/usr/bin/deluged
DAEMON1_ARGS="-d -L warning -l /var/log/deluge/daemon/warning.log"         # none, critical, error, warning, info, debug
DAEMON2=/usr/bin/deluge-web
DAEMON2_ARGS="-L warning -l /var/log/deluge/web/warning.log"               # none, critical, error, warning, info, debug
PIDFILE1=/var/run/$NAME1.pid
PIDFILE2=/var/run/$NAME2.pid
UMASK=0                       # Change this to 0 if running deluged as its own user, org 022
PKGNAME=deluge-daemon
SCRIPTNAME=/etc/init.d/$PKGNAME

# Exit if the package is not installed
[ -x "$DAEMON1" -a -x "$DAEMON2" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$PKGNAME ] && . /etc/default/$PKGNAME

# Load the VERBOSE setting and other rcS variables
[ -f /etc/default/rcS ] && . /etc/default/rcS

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions

if [ -z "$RUN_AT_STARTUP" -o "$RUN_AT_STARTUP" != "YES" ]
then
   log_warning_msg "Not starting $PKGNAME, edit /etc/default/$PKGNAME to start it."
   exit 0
fi

if [ -z "$DELUGED_USER" ]
then
    log_warning_msg "Not starting $PKGNAME, DELUGED_USER not set in /etc/default/$PKGNAME."
    exit 0
fi

#
# Function that starts the daemon/service
#
do_start()
{
   # Return
   #   0 if daemon has been started
   #   1 if daemon was already running
   #   2 if daemon could not be started
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE1 --exec $DAEMON1 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK --test > /dev/null
   RETVAL1="$?"
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE2 --exec $DAEMON2 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK --test > /dev/null
   RETVAL2="$?"
   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] || return 1

   start-stop-daemon --start --background --quiet --pidfile $PIDFILE1 --make-pidfile --exec $DAEMON1 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON1_ARGS
   RETVAL1="$?"
        sleep 2
   start-stop-daemon --start --background --quiet --pidfile $PIDFILE2 --make-pidfile --exec $DAEMON2 \
      --chuid $DELUGED_USER --user $DELUGED_USER --umask $UMASK -- $DAEMON2_ARGS
   RETVAL2="$?"
   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
   # Return
   #   0 if daemon has been stopped
   #   1 if daemon was already stopped
   #   2 if daemon could not be stopped
   #   other if a failure occurred

   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE2
   RETVAL2="$?"
   start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --user $DELUGED_USER --pidfile $PIDFILE1
   RETVAL1="$?"
   [ "$RETVAL1" = "2" -o "$RETVAL2" = "2" ] && return 2

   rm -f $PIDFILE1 $PIDFILE2

   [ "$RETVAL1" = "0" -a "$RETVAL2" = "0" ] && return 0 || return 1
}

case "$1" in
  start)
   [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME1"
   do_start
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  stop)
   [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME1"
   do_stop
   case "$?" in
      0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
      2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
   esac
   ;;
  restart|force-reload)
   log_daemon_msg "Restarting $DESC" "$NAME1"
   do_stop
   case "$?" in
     0|1)
      do_start
      case "$?" in
         0) log_end_msg 0 ;;
         1) log_end_msg 1 ;; # Old process is still running
         *) log_end_msg 1 ;; # Failed to start
      esac
      ;;
     *)
        # Failed to stop
      log_end_msg 1
      ;;
   esac
   ;;
  *)
   echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
   exit 3
   ;;
esac

:
Endofmessage
}

function writeDelugeNotificationPlugin()
{
cat > /var/lib/deluge/.config/deluge/notifications-core.conf <<EOF
{
  "file": 1, 
  "format": 1
}{
  "smtp_recipients": [
    "$__noti_smtp_recipients"
  ], 
  "smtp_enabled": $__noti_smtp_enabled, 
  "subscriptions": {
    "email": [
      "TorrentFinishedEvent"
    ]
  }, 
  "smtp_port": $__noti_smtp_port, 
  "smtp_host": "$__noti_smtp_host", 
  "smtp_from": "$__noti_smtp_from", 
  "smtp_user": "$__noti_smtp_user", 
  "smtp_pass": "$__noti_smtp_pass", 
  "smtp_tls": $__noti_smtp_tls
}
EOF
}

function first_deluge_remove()
{
	clear 

	# stop the deluge-deamon
	invoke-rc.d deluge-daemon stop
	update-rc.d deluge-daemon remove
	
	# delete deluge-deamon
	rm /etc/default/deluge-daemon
	rm /etc/init.d/deluge-daemon
	
	# delete User and group
	deluser deluge
	
	# delete deluge folders log and Home
	rm -r /var/lib/deluge
	rm -r /var/log/deluge
	
	# delete package from System http://dev.deluge-torrent.org/wiki/Installing/Source#RemovingFromSystem
	rm -r /usr/lib/python2.*/dist-packages/deluge*
	rm -r /usr/bin/deluge*
	
	# delete desktop files debian 7
	rm /usr/share/app-install/desktop/deluge.desktop
	rm /usr/share/app-install/icons/deluge.png
}

function apt_deluge_original_setup()
{
	clear 

	# install all needed packages, http://dev.deluge-torrent.org/wiki/Installing/Source
	apt-get install python python-twisted python-twisted-web python-openssl python-simplejson \
	python-setuptools intltool python-xdg python-chardet geoip-database python-libtorrent \
	python-notify python-pygame python-glade2 librsvg2-common xdg-utils python-mako 
}

function apt_deluge_stable_setup()
{
	clear 

	# install all needed packages for Web Server Environment, http://git.deluge-torrent.org/deluge/tree/DEPENDS
	apt-get install -y python python-twisted python-twisted-web python-openssl python-setuptools \
	gettext intltool python-xdg python-chardet python-libtorrent python-mako
}

function apt_deluge_master_setup()
{
	clear 

	# install all needed packages, http://git.deluge-torrent.org/deluge/tree/DEPENDS
	apt-get install -y python python-twisted python-twisted-web python-openssl python-setuptools \
	gettext intltool python-xdg python-chardet python-libtorrent python-mako subversion gcc locate \
	g++
}

function main_setdelugeport()
{
    cmd=(dialog --backtitle "urbanswelt.de - DelugePi Setup." --inputbox "Please enter the Port for your Deluge Web UI." 22 76 16)
    choices=$("${cmd[@]}" 2>&1 >/dev/tty)    
    if [ "$choices" != "" ]; then
        __delugeport=$choices
    else
        break
    fi  
}

function main_newinstall_deluge_stable()
{
	clear 
	# remove older Version without extra step from menu
	first_deluge_remove
	
	# make sure we use the newest packages
	apt-get update
	# apt-get upgrade -y

	# make sure that the group/user deluge exists
	adduser --disabled-password --system --home /var/lib/deluge --gecos "WebBased Deluge Server" --group deluge
	
	# create log Folders
	mkdir -p /var/log/deluge/daemon
	mkdir /var/log/deluge/web
	chmod -R 755 /var/log/deluge
	chown -R deluge /var/log/deluge

	# install all needed packages, http://git.deluge-torrent.org/deluge/tree/DEPENDS
	apt_deluge_stable_setup
	
	# check out the newest stable version 1.3-stable
	cd
	wget -q -N $__delugestablelink
	tar zxfv $__delugestabletar
	cd $__delugestable
	
	# building Deluge
	python setup.py clean -a
	python setup.py build
	python setup.py install --install-layout=deb
	
	# write daemon and config files
	writeDelugeDaemon1
	writeDelugeDaemon2
	
	
	# set permission and start the deluge-deamon
	chmod 755 /etc/init.d/deluge-daemon
	update-rc.d deluge-daemon defaults
	invoke-rc.d deluge-daemon start
	
	# remove install files
	cd
	rm $__delugestabletar
	rm -r $__delugestable
	
	# finish the script
	myipaddress=$(hostname -I | tr -d ' ')
	dialog --backtitle "urbanswelt.de - DelugePi Setup." --msgbox "If everything went right, Deluge should now be available at the URL http://$myipaddress:$__delugeport. You have to finish the setup by visiting that site. Initial Password is deluge." 20 60    
}

function main_plugin_notification()
{
	clear	
	#Input data
	read -p "recipient for this email ? e.g yourname@gmail.com :" __noti_smtp_recipients
	read -p "SMTP enable ? write true :" __noti_smtp_enabled
	read -p "SMTP Port ? e.g. 25 :" __noti_smtp_port
	read -p "SMTP Host ? e.g. smtp.gmail.com :" __noti_smtp_host
	read -p "send From ? e.g. yourname@gmail.com :" __noti_smtp_from
	read -p "SMTP User ? e.g. yourname :" __noti_smtp_user
	read -p "SMTP password ? e.g. yourpassword :" __noti_smtp_pass
	read -p "enable TLS ? write true :" __noti_smtp_tls 
	
	# setup for Plugin
	writeDelugeNotificationPlugin
	chmod 660 /var/lib/deluge/.config/deluge/notifications-core.conf
	chown deluge /var/lib/deluge/.config/deluge/notifications-core.conf
	
	# finish the script
	myipaddress=$(hostname -I | tr -d ' ')
	dialog --backtitle "urbanswelt.de - DelugePi Setup." --msgbox "If everything went right, Deluge should now be available at the URL http://$myipaddress:$__delugeport. You have to finish the setup by visiting that site. Initial Password is deluge." 20 60
}
function main_newinstall_deluge_master()
{
	clear 
	# remove older Version without extra step from menu
	#first_deluge_remove
	
	# make sure we use the newest packages
	apt-get update
	# apt-get upgrade -y

	# make sure that the group/user deluge exists
	#adduser --disabled-password --system --home /var/lib/deluge --gecos "WebBased Deluge Server" --group deluge
	
	# create log Folders
	#mkdir -p /var/log/deluge/daemon
	#mkdir /var/log/deluge/web
	#chmod -R 755 /var/log/deluge
	#chown -R deluge /var/log/deluge

	# install all needed packages, http://git.deluge-torrent.org/deluge/tree/DEPENDS
	apt_deluge_master_setup
	
	# check out the newest master version
	#cd
	#wget -q -N $__delugemasterlink
	#tar zxfv $__delugemastertar
	#cd $__delugemaster
	
	# building Deluge
	#python setup.py clean -a
	#python setup.py build
	#python setup.py install --install-layout=deb
	
	# write daemon and config files
	#writeDelugeDaemon1
	#writeDelugeDaemon2
	
	# set permission and start the deluge-deamon
	#chmod 755 /etc/init.d/deluge-daemon
	#update-rc.d deluge-daemon defaults
	#invoke-rc.d deluge-daemon start

	# remove install files
	#cd
	#rm $__delugemastertar
	#rm -r $__delugemaster
	
	# updatedb for locate deluge
	#updatedb
	
	# finish the script
	#myipaddress=$(hostname -I | tr -d ' ')
	#dialog --backtitle "urbanswelt.de - DelugePi Setup." --msgbox "If everything went right, Deluge should now be available at the URL http://$myipaddress:$__delugeport. You have to finish the setup by visiting that site. Initial Password is deluge." 20 60    
}

function main_remove()
{
	clear
	# remove older Version
	first_deluge_remove
	
	# finish the script
	dialog --backtitle "urbanswelt.de - DelugePi Setup." --msgbox "Deluge was deleted from your System =( " 20 60    
}

# here starts the main script

checkNeededPackages

__delugeport="8112"
__delugestablelink="http://git.deluge-torrent.org/deluge/snapshot/deluge-1.3-stable.tar.gz"
__delugestabletar="deluge-1.3-stable.tar.gz"
__delugestable="deluge-1.3-stable"
__delugemasterlink="http://git.deluge-torrent.org/deluge/snapshot/deluge-master.tar.gz"
__delugemastertar="deluge-master.tar.gz"
__delugemaster="deluge-master"

if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo ./DelugePi_setup'\n"
  exit 1
fi

while true; do
    cmd=(dialog --backtitle "urbanswelt.de - DelugePi Setup." --menu "Choose task." 22 76 16)
    options=(1 "Set special Deluge Port ($__delugeport) not implemented yet"
             2 "New clean Server installation, Branch 1.3.stable"
             3 "New clean Server installation, Branch Master not implemented yet"
             4 "Setup Plugin Notification"
             5 "Update existing Deluge not implemented yet"
             6 "Remove existing Deluge installation")
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)    
    if [ "$choice" != "" ]; then
        case $choice in
            1) main_setdelugeport ;;
            2) main_newinstall_deluge_stable ;;
            3) main_newinstall_deluge_master ;;
            4) main_plugin_notification ;;
            5) main_update ;;
            6) main_remove ;;
        esac
    else
        break
    fi
done
clear
