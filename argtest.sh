#!/bin/sh
set -x

fwcmd=/sbin/ipfw

$fwcmd set enable 3
$fwcmd set disable 4
ipfw() {
	if [ "$1" = "add" ]; then
		subcmd=$1; shift
		rulenumber=$1; shift
		/sbin/ipfw $subcmd $rulenumber set $setnumber $*
	else
		echo "unsupported command in set based script"
		$fwcmd $*
	fi
}

setnumber=3
ipfw add 30001 allow ip from 8.8.8.8 to me
setnumber=4
ipfw add 30001 allow ip from 9.9.9.9 to me

ipfw -S list

