#!/bin/sh
CLEANUP_PIDFILE=/tmp/fiddle_cleanup.pid

ERR_INVALID_ARG=1
ERR_UNKNOWN=2
ERR_DAEMON_FAIL=3

echoerr() { printf "%s\n" "$*" >&2; }
exiterr() { 
	echoerr $1
	exit $2
}

fdl_printhelp() {
	echo "Use -c for cleanup mode. Not intended for human invocation"
}

fdl_cleanup() {
	local waittime
	waittime=20
	echo "begin waiting ${waittime}s for cleanup" $(date) >  /tmp/ran_cleanup
	sleep $waittime
	echo done waiting $(date) >>  /tmp/ran_cleanup
	exit 0
}

while getopts c arg
do
    case ${arg} in
        c)
            fdl_cleanup
            ;;
        ?)
	    fdl_printhelp
            echoerr "invalid argument"
	    exit 1
    esac
done

daemon -p ${CLEANUP_PIDFILE} $0 -c || exiterr "Cleanup process already running." $ERR_DAEMON_FAIL

waittime=5
echo -n "Do you wish to continue? (Y/n) ${waittime} seconds to respond... "
read -t ${waittime}s answer
echo -e "\nAnswer: ${answer}"

case ${answer} in
	[yY])
		echo "killing cleanup task"
		kill $(cat ${CLEANUP_PIDFILE})
		;;
	?)
esac





