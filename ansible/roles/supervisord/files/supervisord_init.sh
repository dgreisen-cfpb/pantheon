#!/bin/bash
# chkconfig: 2345 20 80
#
# supervisord   This scripts turns supervisord on
#
# description:  supervisor is a process control utility.  It has a web based
#               xmlrpc interface as well as a few other nifty features.
# processname:  supervisord
# config: /etc/supervisord.conf
# pidfile: /var/run/supervisord.pid
#

# source function library
. /etc/rc.d/init.d/functions

set -a 

# should probably put both of these options as runtime arguments 
OPTIONS="-c /etc/supervisord.conf"
PIDFILE=/tmp/supervisord.pid

# unset this variable if you don't care to wait for child processes to shutdown before removing the /var/lock/subsys/supervisord lock
WAIT_FOR_SUBPROCESSES=yes

RETVAL=0

start() {
    echo "Starting supervisord: "
        if [ -e $PIDFILE ]; then 
                echo "ALREADY STARTED"
                return 1
        fi

        # start supervisord with options from sysconfig (stuff like -c)
        /usr/bin/supervisord $OPTIONS

        # show initial startup status
        /usr/bin/supervisorctl $OPTIONS status
        
        # only create the subsyslock if we created the PIDFILE
        [ -e $PIDFILE ] && touch /var/lock/subsys/supervisord
}

stop() {
    echo -n "Stopping supervisord: "
    /usr/bin/supervisorctl $OPTIONS shutdown
        if [ -n "$WAIT_FOR_SUBPROCESSES" ]; then 
        echo "Waiting roughly 60 seconds for $PIDFILE to be removed after child processes exit"
        for sleep in  2 2 2 2 4 4 4 4 8 8 8 8 last; do
            if [ ! -e $PIDFILE ] ; then
                echo "Supervisord exited as expected in under $total_sleep seconds"
                break
            else
                if [[ $sleep -eq "last" ]] ; then
                    echo "Supervisord still working on shutting down. We've waited roughly 60 seconds, we'll let it do its thing from here"
                    return 1
                else
                    sleep $sleep
                    total_sleep=$(( $total_sleep + $sleep ))
                fi

            fi
        done
    fi

    # always remove the subsys.  we might have waited a while, but just remove it at this point.
    rm -f /var/lock/subsys/supervisord
}

restart() {
        stop
        start
}

case "$1" in
    start)
        start
        RETVAL=$?
        ;;
    stop)
        stop
        RETVAL=$?
        ;;
    restart|force-reload)
        restart
        RETVAL=$?
        ;;
    reload)
        /usr/bin/supervisorctl $OPTIONS reload
        RETVAL=$?
        ;;
    condrestart)
        [ -f /var/lock/subsys/supervisord ] && restart
        RETVAL=$?
        ;;
    status)
        /usr/bin/supervisorctl status
        RETVAL=$?
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
        exit 1
esac

exit $RETVAL