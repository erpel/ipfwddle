#!/bin/sh
CLEANUP_PIDFILE=/tmp/fiddle_cleanup.pid
CLEANUP_LOGFILE=/tmp/ran_cleanup
RUN_SET=3
PREP_SET=4
WAITTIME=20

# legacy support
waittime=$WAITTIME

fwcmd=/sbin/ipfw

ERR_INVALID_ARG=1
ERR_UNKNOWN=2
ERR_DAEMON_FAIL=3
ERR_PREP_NOT_EMPTY=4
ERR_RULES_FILE_MISSING=5

echoerr() { printf "%s\n" "$*" >&2; }
exiterr() { 
	echoerr "$1"
	exit $2
}

fdl_printhelp() {
	echo "Use -c for cleanup mode. Not intended for human invocation"
	echo "Use -f to specify rules file"
	echo "USe -l to just load the rules file into the run set"
}

fdl_cleanup() {
	echo "begin waiting ${waittime}s for cleanup" $(date) >>  /tmp/ran_cleanup
	sleep $waittime
	echo done waiting $(date) >>  /tmp/ran_cleanup
	
	# actual recovery: swapping back the sets
	$fwcmd set swap $RUN_SET $PREP_SET

	echo cleanup done >> $CLEANUP_LOGFILE
	exit 0
}

# function that performs loading the script without interactive
# confirmation
fdl_load_only() {
	echo "$rules_file"
	. "${rules_file}"
	$fwcmd set swap $PREP_SET $RUN_SET
}

# function to replace ipfw and insert set number
ipfw() {
	if [ "$1" = "add" ]; then
		subcmd=$1; shift
		rulenumber=$1; shift
		/sbin/ipfw -q $subcmd $rulenumber set $PREP_SET $*
	else
		echoerr "unsupported command in set based script: $*"
		$fwcmd $*
	fi
}

while getopts cf:l arg
do
	case ${arg} in
		c)
			fdl_cleanup
			;;
		f)
			rules_file="${OPTARG}"
			;;
		l)
			fdl_load_only
			exit 0
			;;
		?)
			fdl_printhelp
			echoerr "invalid argument"
			exit 1
	esac
done

if [ -z $rules_file ]; then
	exiterr "Rules file missing" $ERR_RULES_FILE_MISSING
fi

echo "Checking if set $PREP_SET is empty"
initial_prep_set_rules=$($fwcmd -S set $PREP_SET  list )
if [ -n "$initial_prep_set_rules" ]; then
	echoerr "Hint: use ipfw delete set $PREP_SET to empty the preparation set"
	exiterr "Set $PREP_SET is not empty" $ERR_PREP_NOT_EMPTY
fi

daemon -p ${CLEANUP_PIDFILE} $0 -c || exiterr "Cleanup process already running." $ERR_DAEMON_FAIL

# currently setting the prep set to diabled by force
$fwcmd set disable $PREP_SET

## actual dangerous work here
. "${rules_file}"
$fwcmd set swap $PREP_SET $RUN_SET

echo -n "Are you still there? (Y/n) ${waittime} seconds to respond... "
read -t ${waittime}s answer
echo -e "\nAnswer: ${answer}"

case ${answer} in
	[yY])
		echo "killing cleanup task"
		kill $(cat ${CLEANUP_PIDFILE})
		$fwcmd delete set $PREP_SET
		;;
	?)
		echo "Finished without killing cleanup task."
		echo "Cleanup will commence after regular timeout of $WAITTIME seconds from initial invocation"
		echo "Do not forget to inspect the result and delete set $PREP_SET afterwards"
		echo "Cleanup task pid: $(cat ${CLEANUP_PIDFILE})"
esac





