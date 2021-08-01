#!/bin/bash
#24.06.2021 by Heyzi

#The script outputs a list of tapes on which a full backup of the specified client was written
#Usage:
#First launch: scriptname.sh clientname
#Second launch: scriptname.sh clientname start_date end_date

dago="1825"
hago=`expr $dago \* 24`
fmt="%-5s %-12s %-12s\n"

#test param
if [ ! -n "$1" ] && [ ! -n "$2" ] && [ ! -n "$3" ]
then
echo "!ALARM, ZERO PARAMETRS INPUTED!"
echo "Usage:"
echo "------------------------------------------------------------"
echo "First launch: scriptname.sh clientname"
echo "Second launch: scriptname.sh clientname start_date end_date"
echo "------------------------------------------------------------"

exit
fi

#Get a list of backup dates
if [ ! -n "$2" ] && [ ! -n "$3" ]
then
fbackup_date=$(/usr/openv/netbackup/bin/admincmd/bpimagelist -l -hoursago "$hago" -client "$1" -st FULL 2>/dev/null |grep "IMAGE" | awk  '{print $14, $15, $11, $20}')
   [[ -z $fbackup_date ]] ||
    {
    echo "$fbackup_date" |
    while read started elapsed schedule fcount
           do
    #calculations...
    started_t=$(date -d @$started +"%m/%d/%Y %H:%M:%S")
    ended=$(expr $elapsed + $started)
    ended_t=$(date -d @$ended +"%m/%d/%Y %H:%M:%S")
    sdate=$(date -d @$started +"%m/%d/%Y %H:%M")
    printf "$fmt" "$1" "\"$sdate\"" "\"$ended_t\""
       done
}
fi

#Get a list of tapes
if [ -n "$2" ] && [ -n "$3" ]
then
/usr/openv/netbackup/bin/admincmd/bpimagelist -l -client "$1"  -d "$2" -e "$3"  -tape | awk '{print $9}' | egrep -v "(NULL|^0$)" | sort -u
fi
