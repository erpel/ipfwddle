# ipfwddle
ipfwddle - IPFW rule application script with lockout prevention

## Usage
./ipfwddle 

## What it does

A cleanup task is started before an operation with the potential to lock out the user running the script.
Then the operation is carried out and the user is asked to confirm success, proving that the user is still
able to interact with the system.
If this confirmation happens in time, the cleanup task is stopped, if not, cleanup should eventually restore access.

## About
ipfwddle is a poor mans replacement for the ferm firewall management tool for iptables on GNU/Linux systems.
Developed on and intended for FreeBSD.


Any feedback or contributions are appreciated.
