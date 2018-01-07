#!/bin/sh

echo() {
	/bin/echo test $1
}


echo A
eval "$(cat evaltest-b.sh)"
. evaltest-b.sh
