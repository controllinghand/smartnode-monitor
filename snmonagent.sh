#!/bin/bash
SHELL=/bin/bash
PATH=$PATH:/usr/sbin
# This is snmonagent script that will collect data every 10 mins
# It will save the info in a data file call snmon.dat
# This file can be view from your local wallet machine via ssh
# This script should be run by root
# root requires the smartcash.conf file for rpcuser and rpcpassword 
# so that it can issue smartcash-cli
# this script will check for that

#Redirect stdout (>) into a named pipe ( <() ) running "tee"
exec > >(tee -i /home/smartadmin/snmon/snmon.dat)
#exec 2>&1

# Go to root home dir
cd

# Check for .smartcash dir in root home
# If not then copy smartcash.conf from smartadmin to root location
# this will allow root to issue smartcash-cli commands if installed by smartadmin
if [[ ! -f ~/.smartcash/smartcash.conf ]]
then
    mkdir ~/.smartcash
    cp /home/smartadmin/.smartcash/smartcash.conf ~/.smartcash
fi

# Get date in UTC seconds from epoc for easy math (Row 1)
vpsdate=$(date +%s)
echo "vpsdate:$vpsdate" 

# Get hostname (Row 2)
hostname=$(hostname)
echo "hostname:$hostname"

# Check to see if smartcashd is running and by who (Row 3)
scuser=$(ps axo user:20,comm | grep smartcashd | awk '{print $1}')
echo "smartcashduser:$scuser"

# Check smartnode status (Row 4)
snstatus=$(smartcash-cli smartnode status | grep status | awk '{print $2" "$3" "$4}' )
echo "smartnodestatus:$snstatus"

# check OS version (Row 5)
osver=$(uname -rv | awk '{print $1 " "$2}')
echo "osversion:$osver"

# Check for OS packages are available for update (Row 6)
npac=$(apt list --upgradable 2>/dev/null | wc -l)
npac=$((npac-1))
echo "ospackagesneedupdate:$npac"

# Check for smartcashd current software version running (Row 7)
snpac=$(smartcash-cli getinfo | grep \"version | awk '{print $2}' | awk -F',' '{print $1}')
echo "smartcashdversion:$snpac"

# Check for smartcashd current protocol version running (Row 8)
snpac=$(smartcash-cli getinfo | grep protocolversion | awk '{print $2}' | awk -F',' '{print $1}')
echo "smartcashdprotocolversion:$snpac"

# Check Disk Space (Row 9)
dskspc=$(df -Th | grep ext4 | awk '{print $6}')
echo "currentdiskspaceused:$dskspc"

# Check that firewall is active (Row 10)
ufwstatus=$(ufw status | grep Status)
echo "ufwstatus:$ufwstatus"
# Check that firewall port 22 is Limited (Row 11)
ufwssh=$(ufw status | grep 22| grep -v v6 | awk '{print $2}')
echo "ufwssh:$ufwssh"
# Check that firewall port 9678 is Allow (Row 12)
ufwscport=$(ufw status | grep 9678| grep -v v6 | awk '{print $2}')
echo "ufwscport:$ufwscport"
# Check that no other ports are open (Row 13)
snufwother=$(ufw status | grep -v -e "Status" -e "22" -e "To" -e "--" -e "9678" |wc -l)
if [[ $snufwother -gt 2 ]]
then
    echo "ufwother:Check Firewall ports only 22 and 9678 should be open"
else
    echo "ufwother:none"
fi

# Check that crontab is set for user that installed smartcashd (Row 14-18)
cronmk=$(crontab -u $scuser -l  2>/dev/null | grep makerun)
echo "cronmakerun:$cronmk"
cronck=$(crontab -u $scuser -l  2>/dev/null | grep checkdaemon)
echo "croncheckdaemon:$cronck"
cronup=$(crontab -u $scuser -l  2>/dev/null | grep upgrade)
echo "cronupgrade:$cronup"
croncl=$(crontab -u $scuser -l  2>/dev/null | grep clearlog)
echo "cronclearlog:$croncl"
cronsnm=$(crontab -u root -l 2>/dev/null | grep snmonagent)
echo "cronsmnonagent:$cronsnm"
