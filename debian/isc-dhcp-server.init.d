#!/bin/sh

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

DHCPD_DEFAULT="${DHCPD_DEFAULT:-/etc/default/isc-dhcp-server}"

# It is not safe to start if we don't have a default configuration...
if [ ! -f "$DHCPD_DEFAULT" ]; then
	echo "$DHCPD_DEFAULT does not exist! - Aborting..."
	if [ "$DHCPD_DEFAULT" = "/etc/default/isc-dhcp-server" ]; then
		echo "Run 'dpkg-reconfigure isc-dhcp-server' to fix the problem."
	fi
	exit 0
fi

. /lib/lsb/init-functions

# Read init script configuration
[ -f "$DHCPD_DEFAULT" ] && . "$DHCPD_DEFAULT"

NAME4=dhcpd
NAME6=dhcpd6

DESC4="ISC DHCPv4 server"
DESC6="ISC DHCPv6 server"

# use already specified config file or fallback to defaults
DHCPDv4_CONF=${DHCPDv4_CONF:-/etc/dhcp/dhcpd.conf}
DHCPDv6_CONF=${DHCPDv6_CONF:-/etc/dhcp/dhcpd.conf}

# try to read pid file name from config file or fallback to defaults
if [ -z "$DHCPDv4_PID" ]; then
	DHCPDv4_PID=$(sed -n -e 's/^[ \t]*pid-file-name[ \t]*"\(.*\)"[ \t]*;.*$/\1/p' < "$DHCPDv4_CONF" 2>/dev/null | head -n 1)
fi
if [ -z "$DHCPDv6_PID" ]; then
	DHCPDv6_PID=$(sed -n -e 's/^[ \t]*pid-file-name[ \t]*"\(.*\)"[ \t]*;.*$/\1/p' < "$DHCPDv6_CONF" 2>/dev/null | head -n 1)
fi
DHCPDv4_PID="${DHCPDv4_PID:-/var/run/dhcpd.pid}"
DHCPDv6_PID="${DHCPDv4_PID:-/var/run/dhcpd6.pid}"

test_config()
{
        VERSION="$1"
	CONF="$2"

	if ! /usr/sbin/dhcpd -t $VERSION -q -cf "$CONF" > /dev/null 2>&1; then
		echo "dhcpd self-test failed. Please fix $CONF."
		echo "The error was: "
		/usr/sbin/dhcpd -t $VERSION -cf "$CONF"
		exit 1
	fi
}

check_status()
{
        OPTION="$1"
        PIDFILE="$2"
        NAME="$3"

        if [ ! -r "$PIDFILE" ]; then
                test "$OPTION" != -v || echo "$NAME is not running."
		return 3
        fi

        if read pid < "$PIDFILE" && ps -p "$pid" > /dev/null 2>&1; then
		test "$OPTION" != -v || echo "$NAME is running."
		return 0
        else
		test "$OPTION" != -v || echo "$NAME is not running but $PIDFILE exists."
		return 1
        fi
}

start_daemon()
{
	VERSION="$1"
	CONF="$2"
	NAME="$3"
	PIDFILE="$4"
	DESC="$5"

	shift 5
	INTERFACES="$*"

	test_config "$VERSION" "$CONF"
	log_daemon_msg "Starting $DESC" "$NAME"

	if [ -e "$DHCPD_PID" ]; then
		log_failure_msg "dhcpd service already running (pid file $PIDFILE currenty exists)"
		exit 1
	fi

	start-stop-daemon --start --quiet --pidfile $PIDFILE \
		--exec /usr/sbin/dhcpd -- $VERSION -q -cf $CONF $INTERFACES
	sleep 2

	if check_status -q $PIDFILE $NAME; then
		log_end_msg 0
	else
		log_failure_msg "check syslog for diagnostics."
		log_end_msg 1
		exit 1
	fi
}

stop_daemon()
{
	if check_status -q $DHCPDv4_PID $NAME4; then
		log_daemon_msg "Stopping $DESC4" "$NAME4"
		start-stop-daemon --stop --quiet --pidfile $DHCPDv4_PID
		log_end_msg $?
		rm -f "$DHCPDv4_PID"
	fi

	if check_status -q $DHCPDv6_PID $NAME6; then
		log_daemon_msg "Stopping $DESC6" "$NAME6"
		start-stop-daemon --stop --quiet --pidfile $DHCPDv6_PID
		log_end_msg $?
		rm -f "$DHCPDv6_PID"
	fi
}

case "$1" in
	start)
		if test -n "$INTERFACESv4"; then
			start_daemon "-4" "$DHCPDv4_CONF" "$NAME4" \
				"$DHCPDv4_PID" "$DESC4" "$INTERFACESv4"
		fi
		if test -n "$INTERFACESv6"; then
			start_daemon "-6" "$DHCPDv6_CONF" "$NAME6" \
				"$DHCPDv6_PID" "$DESC6" "$INTERFACESv6"
		fi
		;;
	stop)
		stop_daemon
		;;
	restart | force-reload)
		$0 stop
		sleep 2
		$0 start
		if [ "$?" != "0" ]; then
			exit 1
		fi
		;;
	status)
		echo -n "Status of $DESC4: "
		check_status -v $DHCPv4_PID $NAME4
		STATUSv4="$?"
		echo -n "Status of $DESC6: "
		check_status -v $DHCPv6_PID $NAME6
		exit "$(($STATUSv4|$?))"
		;;
	*)
		echo "Usage: $0 {start|stop|restart|force-reload|status}"
		exit 1 
esac

exit 0
