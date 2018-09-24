#!/bin/sh

#
# selenoid	Selenoid selenium hub implementation
# chkconfig: 345 99 01

# Source functions
. /etc/rc.d/init.d/functions

DAEMON=selenoid
BROWSERS_FILE=/root/.aerokube/selenoid/browsers.json

[ -e /etc/sysconfig/$DAEMON ] && . /etc/sysconfig/$DAEMON

LOCKFILE=/var/lock/subsys/$DAEMON

cd /opt

service_start()
{
    #
    # Download configuration manager
    # creates 'cm' executable
    [ -x cm ] || curl -s https://aerokube.com/cm/bash | bash

	echo -n "Starting $DAEMON..."
    [ -f $BROWSERS_FILE ] || ./cm selenoid configure --browsers "${browsers}" --last-versions ${last_versions}
	./cm selenoid start --port ${selenium_port} ${enable_vnc ? "--vnc" : ""}
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && touch $LOCKFILE
	return $RETVAL
}

service_stop()
{
	printf "%-50s" "Stopping $DAEMON..."
	./cm selenoid stop
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && rm -f $PIDFILE $LOCKFILE
	return $RETVAL
}

service_status()
{
	./cm selenoid status
}

case "$1" in
start)
	service_start
;;
stop)
	service_stop
;;
restart)
	service_stop
	service_start
;;
status)
	service_status
;;
*)
	echo "Usage: $0 {start|stop|status}"
	exit 3
esac