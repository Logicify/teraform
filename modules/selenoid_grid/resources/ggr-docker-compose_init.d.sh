#!/bin/sh

#
# ggr-docker-compose	Start ggr load balancer and friends
# chkconfig: 345 99 01

# Source functions
. /etc/rc.d/init.d/functions

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin"

DAEMON="ggr-docker-compose"
DOCKER_FILE="/opt/docker-data/docker-compose.yml"

docker_compose_cmd="docker-compose -f $DOCKER_FILE"

[ -e /etc/sysconfig/$DAEMON ] && . /etc/sysconfig/$DAEMON

LOCKFILE=/var/lock/subsys/$DAEMON

service_start()
{
	which docker-compose || exit 5
	echo -n "Starting $DAEMON..."
	/opt/ggr-quota-update.sh
	$docker_compose_cmd up -d
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && touch $LOCKFILE
	return $RETVAL
}

service_stop()
{
	printf "%-50s" "Stopping $DAEMON..."
	$docker_compose_cmd down
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && rm -f ${PIDFILE} ${LOCKFILE}
	return $RETVAL
}

service_status()
{
	$docker_compose_cmd ps
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