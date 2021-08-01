#!/bin/bash
hago="744"

LOGFILE="/tmp/bkp_report_full.txt"
rm -f "$LOGFILE"

function calculcation_size {
/usr/openv/netbackup/bin/admincmd/bpimagelist -policy "$policy" -d $started_t -e $ended_t 2>/dev/null | \
  awk 'BEGIN {total_size=0}
   {if($1=="IMAGE"){
    client_name[$2]
    size[$2]=size[$2] + $19}}
   END { for (i in client_name) {
        UNIT="KB"
        total_size=total_size+size[i]
        if (size[i]>1024) {size[i]=size[i]/1024;UNIT="MB"}
        if (size[i]>1024) {size[i]=size[i]/1024;UNIT="GB"}
        if (size[i]>1024) {size[i]=size[i]/1024;UNIT="TB"}
        printf("%-30s %10.2f %s\n",i,size[i],UNIT) >> "/tmp/bkp_report_full.txt"
       }
    }'
}

#get active clients
for policy in `/usr/openv/netbackup/bin/admincmd/bppllist -allpolicies -L | egrep "Policy Name|Active|Schedule.*Oracle_Full" | grep -EB2 Oracle_Full | awk '/Active.*yes/{print x};{x=$3}'`
  do
   fbackup_date=$(/usr/openv/netbackup/bin/admincmd/bpimagelist  -l -hoursago "$hago" -policy "$policy" -st FULL 2>/dev/null |awk  '{print $14, $15, $11}' | head -n1)
   [[ -z $fbackup_date ]] ||
    {
    echo "$fbackup_date" |
    while read started elapsed schedule
    do
    started_t=$(date -d @$started +"%m/%d/%Y %H:%M:%S")
    ended=$(expr $elapsed + $started)
    ended_t=$(date -d @$ended +"%m/%d/%Y %H:%M:%S")

    bkp_array=$(/usr/openv/netbackup/bin/admincmd/nbpemreq -subsystems screen 1 | egrep "(PolicyClient::O|Oracle_Full::0)" | egrep -v "(Local_master|Catalog|Schedule:)")
    next_bkp_time=$(echo "$bkp_array" | grep "$policy" -A1 |  grep -P -o 'DT=.+?(?=\()'| sed 's/DT=//' | head -c -5 )            

    echo $(date -d @$started +"%Y/%m/%d %H:%M") "("Elapsed: $(date +%H:%M:%S -ud @${elapsed})h")" >> "$LOGFILE"
    echo "$next_bkp_time" >> "$LOGFILE"
    calculcation_size
    echo "------------------------------------------" >> "$LOGFILE"
   done
}
done

[ -f "$LOGFILE" ] &&
{ 
  cat $LOGFILE  | /usr/bin/nail -s "$HOSTNAME full backup schedule" -r $MAIL_FROM $MAIL_USER
}
