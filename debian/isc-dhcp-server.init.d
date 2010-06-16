#!/bin/sh
#
#

### BEGIN INIT INFO
# Provides:          isc-dhcp-server
# Required-Start:    $remote_fs $network $syslog
# Required-Stop:     $remote_fs $network $syslog
# Should-Start:      $local_fs slapd $named
# Should-Stop:       $local_fs slapd
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: DHCP server
# Description:       Dynamic Host Configuration Protocol Server
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

test -f /usr/sbin/dhcpd || exit 0

# It is not safe to start if we don't have a default configuration...
if [ ! -f /etc/default/isc-dhcp-server ]; then
	echo "/etc/default/isc-dhcp-server does not exist! - Aborting..."
	echo "Run 'dpkg-reconfigure isc-dhcp-server' to fix the problem."
	exit 0
fi

. /lib/lsb/init-functions

# Read init script configuration (so far only interfaces the daemon
# should listen on.)
[ -f /etc/default/isc-dhcp-server ] && . /etc/default/isc-dhcp-server

NAME=dhcpd
DESC="ISC DHCP server"
DHCPDPID=/var/run/dhcpd.pid

test_config()
{
	if ! /usr/sbin/dhcpd -t -q > /dev/null 2>&1; then
		echo "dhcpd self-test failed. Please fix the config file."
		echo "The error was: "
		/usr/sbin/dhcpd -t
		exit 1
	fi
}

# single arg is -v for messages, -q for none
check_status()
{
    if [ ! -r "$DHCPDPID" ]; then
	test "$1" != -v || echo "$NAME is not running."
	return 3
    fi
    if read pid < "$DHCPDPID" && ps -p "$pid" > /dev/null 2>&1; then
	test "$1" != -v || echo "$NAME is running."
	return 0
    else
	test "$1" != -v || echo "$NAME is not running but $DHCPDPID exists."
	return 1
    fi
}

case "$1" in
	start)
		test_config
		log_daemon_msg "Starting $DESC" "$NAME"
		start-stop-daemon --start --quiet --pidfile $DHCPDPID \
			--exec /usr/sbin/dhcpd -- -q $INTERFACES
		sleep 2

		if check_status -q; then
			log_end_msg 0
		else
			log_failure_msg "check syslog for diagnostics."
			log_end_msg 1
			exit 1
		fi
		;;
	stop)
		log_daemon_msg "Stopping $DESC" "$NAME"
		start-stop-daemon --stop --quiet --pidfile $DHCPDPID
		log_end_msg $?
		rm -f "$DHCPDPID"
		;;
	restart | force-reload)
		test_config
		$0 stop
		sleep 2
		$0 start
		if [ "$?" != "0" ]; then
			exit 1
		fi
		;;
	status)
		echo -n "Status of $DESC: "
		check_status -v
		exit "$?"
		;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload|status}"
		exit 1 
esac

exit 0
