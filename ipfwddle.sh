#!/bin/sh
fdl_CLEANUP_PIDFILE=/tmp/fiddle_cleanup.pid
fdl_CLEANUP_LOGFILE=/tmp/ran_cleanup
fdl_RUN_SET=3
fld_PREP_SET=4
fdl_WAITTIME=20

fdl_fwcmd=/sbin/ipfw

fdl_ERR_INVALID_ARG=1
fdl_ERR_UNKNOWN=2
fdl_ERR_DAEMON_FAIL=3
fdl_ERR_PREP_NOT_EMPTY=4
fdl_ERR_RULES_FILE_MISSING=5

fld_echoerr() { printf "%s\n" "$*" >&2; }
fdl_exiterr() {
	fld_echoerr "$1"
	exit $2
}

fdl_printhelp() {
	echo "Use -c for cleanup mode. Not intended for human invocation"
	echo "Use -f to specify rules file"
	echo "USe -l to just load the rules file into the run set"
}

fdl_cleanup() {
	echo "begin waiting ${fdl_WAITTIME}s for cleanup" $(date) >>  /tmp/ran_cleanup
	sleep $fdl_WAITTIME
	echo done waiting $(date) >>  /tmp/ran_cleanup
	
	# actual recovery: swapping back the sets
	$fdl_fwcmd set swap $fdl_RUN_SET $fld_PREP_SET

	echo cleanup done >> $fdl_CLEANUP_LOGFILE
	exit 0
}

# function that performs loading the script without interactive
# confirmation
fdl_load_only() {
	echo "$fdl_rules_file"
	. "${fdl_rules_file}"
	$fdl_fwcmd set swap $fld_PREP_SET $fdl_RUN_SET
}

# function to replace ipfw and insert set number
ipfw() {
	if [ "$1" = "add" ]; then
		subcmd=$1; shift
		rulenumber=$1; shift
		/sbin/ipfw -q $subcmd $rulenumber set $fld_PREP_SET $*
	else
		fld_echoerr "unsupported command in set based script: $*"
		$fdl_fwcmd $*
	fi
}

while getopts cf:l arg
do
	case ${arg} in
		c)
			fdl_cleanup
			;;
		f)
			fdl_rules_file="${OPTARG}"
			;;
		l)
			fdl_load_only
			exit 0
			;;
		?)
			fdl_printhelp
			fld_echoerr "invalid argument"
			exit 1
	esac
done

if [ -z $fdl_rules_file ]; then
	fdl_exiterr "Rules file missing" $fdl_ERR_RULES_FILE_MISSING
fi

echo "Checking if set $fld_PREP_SET is empty"
initial_prep_set_rules=$($fdl_fwcmd -S set $fld_PREP_SET  list )
if [ -n "$initial_prep_set_rules" ]; then
	fld_echoerr "Hint: use ipfw delete set $fld_PREP_SET to empty the preparation set"
	fdl_exiterr "Set $fld_PREP_SET is not empty" $fdl_ERR_PREP_NOT_EMPTY
fi

daemon -p ${fdl_CLEANUP_PIDFILE} $0 -c || fdl_exiterr "Cleanup process already running." $fdl_ERR_DAEMON_FAIL

# currently setting the prep set to diabled by force
$fdl_fwcmd set disable $fld_PREP_SET

## actual dangerous work here
. "${fdl_rules_file}"
$fdl_fwcmd set swap $fld_PREP_SET $fdl_RUN_SET

echo -n "Are you still there? (Y/n) ${fdl_WAITTIME} seconds to respond... "
read -t ${fdl_WAITTIME}s fdl_answer
echo -e "\nAnswer: ${fdl_answer}"

case ${fdl_answer} in
	[yY])
		echo "killing cleanup task"
		kill $(cat ${fdl_CLEANUP_PIDFILE})
		$fdl_fwcmd delete set $fld_PREP_SET
		;;
	?)
		echo "Finished without killing cleanup task."
		echo "Cleanup will commence after regular timeout of $fdl_WAITTIME seconds from initial invocation"
		echo "Cleanup task pid: $(cat ${fdl_CLEANUP_PIDFILE})"
esac





