#!/bin/bash
# deluge-1.3.5 - install latest stable Deluge Version on Raspberry PI Server
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

function writeDelugeDeamon1()
{
	cat > /etc/default/deluge-daemon << _EOF_
# Configuration for /etc/init.d/deluge-daemon
# The init.d script will only run if this variable non-empty.
DELUGED_USER="deluge"             # !!!CHANGE THIS!!!!

# Should we run at startup?
RUN_AT_STARTUP="YES"
_EOF_
}

function writeDelugeDeamon2()
{
	cat > /etc/init.d/deluge-daemon << _EOF_
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
_EOF_
}

function writeDelugeNotificationPlugin()
{
	cat > /var/lib/deluge/.config/deluge/notifications-core.conf << _EOF_
{
  "file": 1, 
  "format": 1
}{
  "smtp_recipients": [
    "yourname@gmail.com"
  ], 
  "smtp_enabled": true, 
  "subscriptions": {
    "email": [
      "TorrentFinishedEvent"
    ]
  }, 
  "smtp_port": 25, 
  "smtp_host": "smtp.gmail.com", 
  "smtp_from": "yourname@gmail.com", 
  "smtp_user": "yourname", 
  "smtp_pass": "yourpassword", 
  "smtp_tls": true
}
_EOF_
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

	# make sure we use the newest packages
	apt-get update
	apt-get upgrade -y

	# make sure that the group/user deluge exists
	adduser --disabled-password --system --home /var/lib/deluge --gecos "WebBased Deluge Server" --group deluge
	
	# create log Folders
	mkdir -p /var/log/deluge/daemon
	mkdir /var/log/deluge/web
	chmod -R 755 /var/log/deluge
	chown -R deluge /var/log/deluge

	# install all needed packages, http://git.deluge-torrent.org/deluge/tree/DEPENDS
	apt-get install -y python python-twisted python-twisted-web python-openssl python-setuptools gettext intltool python-xdg python-chardet python-libtorrent python-mako
	
	# check out the newest stable version 1.3.5-stable with git
	cd
	git clone git://deluge-torrent.org/deluge.git &&
	cd ~/deluge
	git checkout 1.3-stable
	
	# building Deluge
	python setup.py clean -a &&
	python setup.py build &&
	python setup.py install --install-layout=deb
	
	# write deamon and config files
	writeDelugeDeamon1
	writeDelugeDeamon2
	writeDelugeNotificationPlugin
	
	# set permission and start the deluge-deamon
	chmod 755 /etc/init.d/deluge-daemon
	chmod 660 /var/lib/deluge/.config/deluge/notifications-core.conf
	chown deluge /var/lib/deluge/.config/deluge/notifications-core.conf
	update-rc.d deluge-daemon defaults
	sudo invoke-rc.d deluge-daemon start
	
	# finish the script
	myipaddress=$(hostname -I | tr -d ' ')
	dialog --backtitle "urbanswelt.de - DelugePi Setup." --msgbox "If everything went right, Deluge should now be available at the URL http://$myipaddress:$__delugeport. You have to finish the setup by visiting that site Password is deluge." 20 60    
}

# here starts the main script

checkNeededPackages

__delugeport="8112"

if [ $(id -u) -ne 0 ]; then
  printf "Script must be run as root. Try 'sudo ./DelugePi_setup'\n"
  exit 1
fi

while true; do
    cmd=(dialog --backtitle "urbanswelt.de - DelugePi Setup." --menu "Choose task." 22 76 16)
    options=(1 "Set special Deluge Port ($__delugeport)"
             2 "New installation, 1.3.5 stable"
             3 "New installation, Branch Master not implemented yet"
             4 "Update existing Deluge not implemented yet"
			 5 "Remove existing Deluge installation not implemented yet")
    choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)    
    if [ "$choice" != "" ]; then
        case $choice in
            1) main_setdelugeport ;;
            2) main_newinstall_deluge_stable ;;
            3) main_newinstall_deluge_master ;;
            4) main_update ;;
			5) main_remove ;;
        esac
    else
        break
    fi
done
clear