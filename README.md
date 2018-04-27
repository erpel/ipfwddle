# ipfwddle
ipfwddle - IPFW rule application script with lockout prevention

## Usage
./ipfwddle -f path/to/scriptfile.sh

### Script file format

The script file is sourced into the main file. The ipfw command in this context has been replaced with a function that calls /sbin/ipfw and inserts a set number (4) into the commands.
## What it does

A cleanup task is started before an operation with the potential to lock out the user running the script.
Then the operation is carried out and the user is asked to confirm success, proving that the user is still
able to interact with the system.
If this confirmation happens in time, the cleanup task is stopped, if not, cleanup should eventually restore access.

The cleanup currently consists of swapping back the rule sets used for prepraration and the active one.


All commands from the script file provided to the -f argument are executed.
Then the set into which the rules have been inserted is swapped with the active set of ipfwddle managed rules.

### Exit codes
ERR\_INVALID\_ARG=1
ERR\_UNKNOWN=2
ERR\_DAEMON\_FAIL=3
ERR\_PREP\_NOT\_EMPTY=4
ERR\_RULES\_FILE\_MISSING=5


## Caveats

ipfwddle currently does not deal with tables.
I do not know what else it does not deal with. Assume it just deals with rules.
ipfwddle has paths to the ipfw binary and its supporting files (logs and pids) hard coded in variables.
There are a lot of things that ipfwddle assumes but are not checked at the moment.
If contact is lost before the swap of the rules or something else messes with the expected order of things, the cleanup will either not work or make things wors.
## About
ipfwddle is a poor mans replacement for the ferm firewall management tool for iptables on GNU/Linux systems.
Developed on and intended for FreeBSD.

# Code style
The project has almost no style but for consistency tabs are used for indentation exclusively until something easier is chosen.

Any feedback or contributions are appreciated.
