#!/bin/sh

check_set_empty() {
	check_set_rules=$(ipfw -S set $1  list )
	if [ -z "$check_set_rules" ]; then
		echo "$1 is empty"
		return 0
	else
		echo "$1 is not empty"
		return 1
	fi
}

ipfw -S list
check_set_empty 5
check_set_empty 6
