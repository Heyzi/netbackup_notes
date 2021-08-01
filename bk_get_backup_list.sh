#!/bin/bash
#28.06.2021 by Heyzi
#The script outputs a list backups of the specified policy or client
#Usage:
#Launch: scriptname.sh policy/client name daysago full\diff\arc\all


#output format
fmt="%-20s |%4s| Started: %-18s| Elapsed: %-12s| Size: %-8sGB|  Files: %-12s \n"


#test param
if [ ! -n "$1" ] && [ ! -n "$2" ] && [ ! -n "$3" ]
then
echo "!ALARM, ZERO PARAMETRS INPUTED!"
echo "Usage:"
echo "------------------------------------------------------------"
echo "Launch: scriptname.sh policyname\clientname daysago full\diff\arc\all"
echo "------------------------------------------------------------"

exit
fi

if [ -n "$1" ]; then

        /usr/openv/netbackup/bin/admincmd/bppllist -l  | { grep -w "$1" || false; } &>/dev/null

                if [ "$?" -ne "0" ]; then

                        /usr/openv/netbackup/bin/admincmd/bpplclients  | { grep -w "$1" || false; } &>/dev/null
                        if [ "$?" -ne "0" ]; then
                                echo "No such policy or client. Try again."
                                exit 1;
                        else
                                PCVAR="-client $1"
                        fi
        else 
                        PCVAR="-policy $1"
        fi
fi

if [ -n "$2" ]
        then
        if [[ "$2"  =~ ^[0-9]+$ ]]; then
        dago=$2
        else
            echo "Wrong daysago value"
                exit 1;
        fi
else
echo "Wrong dayago value"
exit 1;
fi


if [ -n "$3" ]
        then
        if [[ "$3"  == full ]]; then
        sched_type="-st FULL"
        elif
           [[ "$3"  == diff ]]; then
          sched_type="-st INCR"
        elif
           [[ "$3"  == arc ]]; then
          sched_type="-st CINC"
                elif
           [[ "$3"  == all ]]; then
          sched_type=""
        else
            echo "Wrong schedule type"
                exit 1;
        fi
else 
echo "wrong schedule type"
exit 1;
fi

#days to hours
hago=`expr $dago \* 24`



fbackup_date=$(/usr/openv/netbackup/bin/admincmd/bpimagelist -l -hoursago "$hago" $PCVAR $sched_type  2>/dev/null | grep -v "Default-A" |grep "IMAGE" | awk  '{print $14, $15, $11, $20, $12}')
   [[ -z $fbackup_date ]] && echo "No backup data found, try to extend days count"

  [[ -z $fbackup_date ]] ||
    {
    echo "$fbackup_date" |
    while read started elapsed schedule fcount schd_type
           do
    #calculations...
    started_t=$(date -d @$started +"%m/%d/%Y %H:%M:%S")
    ended=$(expr $elapsed + $started)
    ended_t=$(date -d @$ended +"%m/%d/%Y %H:%M:%S")
    bkp_size=$(/usr/openv/netbackup/bin/admincmd/bpimagelist $PCVAR -d $started_t -e $ended_t 2>/dev/null | grep "IMAGE" | awk '{s+=$19} END {printf("%.2f\n", s/(1024*1024))}')
    sdate=$(date -d @$started +"%Y/%m/%d %H:%M")
    telapsed=$(echo $((elapsed/3600))"h:"$((elapsed%3600/60))"m:"$((elapsed%60))"s")
        if [[ "$schd_type"  == 0 ]]; then
        sched_typef="FULL"
        elif
           [[ "$schd_type"  == 1 ]]; then
          sched_typef="DIFF"
        elif
           [[ "$schd_type"  == 4 ]]; then
          sched_typef="ARC"
        fi
    printf "$fmt" "$1" "$sched_typef" "$sdate" "$telapsed" "$bkp_size" "$fcount"
        done
 }
