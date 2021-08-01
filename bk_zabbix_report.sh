#!/bin/bash
#tld0_st robot0 scrtach
#tld1_st robot0 scrtach
#tld2_st robot0 scrtach
#total_ej total eject tapes
#daily_size2 backup size for 24h

daily_size2=0

tld0_st=`/usr/openv/volmgr/bin/vmquery -w -a|awk 'NR>3 {print $1, $11, $12}' | grep Scratch | grep 0_TLD | wc -l`
tld1_st=`/usr/openv/volmgr/bin/vmquery -w -a|awk 'NR>3 {print $1, $11, $12}' | grep Scratch | grep 1_TLD | wc -l`
tld2_st=`/usr/openv/volmgr/bin/vmquery -w -a|awk 'NR>3 {print $1, $11, $12}' | grep Scratch | grep 2_TLD | wc -l`
total_ej=`/usr/openv/volmgr/bin/vmquery -pn Eject -bx | grep TLD | wc -l`


data_size2=$(/usr/openv/netbackup/bin/admincmd/bpimagelist -U -hoursago 24  2>/dev/null | grep -v "^[KB-]" | awk '{ print $5 }')
if ! [[ "$data_size2" =~ "[ 0-9]+$" ]]
  then
  daily_size2=0
  else
  for backup_data2 in $data_size2;
    do
    daily_size2=$(( $backup_data2 + daily_size2 ));
    done
fi

#to files

echo $tld0_st > /opt/reports/tld0_scratch
echo $tld1_st > /opt/reports/tld1_scratch
echo $tld2_st > /opt/reports/tld2_scratch
echo $total_ej > /opt/reports/eject_count
echo $daily_size2 > /opt/reports/daily_size2
