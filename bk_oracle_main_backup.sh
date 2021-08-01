#!/bin/bash
#---------------------------------------------------------------------------
#VARS
#---------------------------------------------------------------------------
#first try get sid from policy name
export ORACLE_SID=`echo ${NB_ORA_POLICY^^} | awk -F  "_" '{print $(NF)}'`
export ORACLE_HOME=`cat /etc/oratab |grep -v "^#"|grep -w $ORACLE_SID|cut -d":" -f2`

#second try - from started db's
if [ -z $ORACLE_HOME ] 
then
  export ORACLE_SID=`ps ax | egrep ".*mon_"  | grep -v grep | awk -F  "_" '{print $(NF)}' | head -1`
  export ORACLE_HOME=`cat /etc/oratab |grep -v "^#"|grep $ORACLE_SID|cut -d":" -f2`
fi

export ORACLE_USER=oracle
RMAN=$ORACLE_HOME/bin/rman
TARGET_CONNECT_STR=/
CUSER=`id |cut -d"(" -f2 | cut -d ")" -f1`
SECONDS=0

#---------------------------------------------------------------------------
#Detect host location
#---------------------------------------------------------------------------
LOC_DETECT=$(echo "$NB_ORA_SERV" | cut -c 1)
if [ "$LOC_DETECT" = "p" ]
then
 export LOCATION=rcat
 export BKPLOCATION=SPB
else
 export LOCATION=mrcat
 export BKPLOCATION=MSK
fi

#---------------------------------------------------------------------------
#Log file
#---------------------------------------------------------------------------
RMAN_LOG_FILE=${0}_$ORACLE_SID.log

#---------------------------------------------------------------------------
#Log summary info
#---------------------------------------------------------------------------
echo >> $RMAN_LOG_FILE
chmod 666 $RMAN_LOG_FILE
echo "===========================" >> $RMAN_LOG_FILE
echo "Script $0" >> $RMAN_LOG_FILE
echo "==== $NB_ORA_PC_SCHED started on `date` ====" >> $RMAN_LOG_FILE
echo "RMAN: $RMAN" >> $RMAN_LOG_FILE
echo "ORACLE_SID: $ORACLE_SID" >> $RMAN_LOG_FILE
echo "ORACLE_USER: $ORACLE_USER" >> $RMAN_LOG_FILE
echo "ORACLE_HOME: $ORACLE_HOME" >> $RMAN_LOG_FILE
echo "NB_ORA_FULL: $NB_ORA_FULL" >> $RMAN_LOG_FILE
echo "NB_ORA_INCR: $NB_ORA_INCR" >> $RMAN_LOG_FILE
echo "NB_ORA_CINC: $NB_ORA_CINC" >> $RMAN_LOG_FILE
echo "NB_ORA_SERV: $NB_ORA_SERV" >> $RMAN_LOG_FILE
echo "NB_ORA_POLICY: $NB_ORA_POLICY" >> $RMAN_LOG_FILE
echo "NB_ORA_SCHED: $NB_ORA_SCHED" >> $RMAN_LOG_FILE
echo "NB_ORA_PC_SCHED: $NB_ORA_PC_SCHED" >> $RMAN_LOG_FILE
echo "===========================" >> $RMAN_LOG_FILE

# ---------------------------------------------------------------------------
if [ "$NB_ORA_PC_SCHED" = "Oracle_Full" ]
then
NB_BKP="Full"
CMD_STR="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'
$RMAN target / catalog rcat/rcat@${LOCATION} msglog $RMAN_LOG_FILE append << EOF

RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' parms 'ENV=(NB_ORA_POLICY=$NB_ORA_POLICY,NB_ORA_SCHED=Default-Application-Backup)' RATE 300M;
BACKUP INCREMENTAL LEVEL=0 SKIP INACCESSIBLE TAG ${BKPLOCATION}_FULL FILESPERSET 5 FORMAT 'dbf_%d_%I_%T_%s_%t_%p' DATABASE;
BACKUP TAG ${BKPLOCATION}_FULL filesperset 50 FORMAT 'arc_%d_%I_%T_%s_%t_%p' ARCHIVELOG ALL DELETE INPUT;
BACKUP TAG ${BKPLOCATION}_FULL FORMAT 'ctrl_%d_%I_%T_%s_%t_%p' CURRENT CONTROLFILE;
RELEASE CHANNEL ch00;
}
EOF
"
elif [ "$NB_ORA_PC_SCHED" = "Oracle_Eject" ]
then
NB_BKP="Eject"
CMD_STR="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'
$RMAN target / catalog rcat/rcat@${LOCATION} msglog $RMAN_LOG_FILE append << EOF

RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' parms 'ENV=(NB_ORA_POLICY=$NB_ORA_POLICY,NB_ORA_SCHED=Eject-Application-Backup)' RATE 300M;
BACKUP INCREMENTAL LEVEL=0 SKIP INACCESSIBLE TAG ${BKPLOCATION}_EJECT FILESPERSET 5 FORMAT 'dbf_%d_%I_%T_%s_%t_%p' DATABASE;
BACKUP TAG ${BKPLOCATION}_EJECT filesperset 50 FORMAT 'arc_%d_%I_%T_%s_%t_%p' ARCHIVELOG ALL DELETE INPUT;
BACKUP TAG ${BKPLOCATION}_EJECT FORMAT 'ctrl_%d_%I_%T_%s_%t_%p' CURRENT CONTROLFILE;
RELEASE CHANNEL ch00;
}
EOF
"
elif [ "$NB_ORA_PC_SCHED" = "Oracle_Diff" ]
then
NB_BKP="Diff"
CMD_STR="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'
$RMAN target / catalog rcat/rcat@${LOCATION} msglog $RMAN_LOG_FILE append << EOF

RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' parms 'ENV=(NB_ORA_POLICY=$NB_ORA_POLICY,NB_ORA_SCHED=Default-Application-Backup)';
BACKUP INCREMENTAL LEVEL=1 SKIP INACCESSIBLE TAG ${BKPLOCATION}_INC1 FILESPERSET 5 FORMAT 'dbf_%d_%I_%T_%s_%t_%p' DATABASE;
BACKUP TAG ${BKPLOCATION}_INC1 filesperset 20 FORMAT 'arc_%d_%I_%T_%s_%t_%p' ARCHIVELOG ALL DELETE INPUT;
BACKUP TAG ${BKPLOCATION}_INC1 FORMAT 'ctrl_%d_%I_%T_%s_%t_%p' CURRENT CONTROLFILE;
RELEASE CHANNEL ch00;
}
EOF
"

elif [ "$NB_ORA_PC_SCHED" = "Oracle_Arc" ]
then
NB_BKP="Arclog"
CMD_STR="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
export NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'
$RMAN target / catalog rcat/rcat@${LOCATION} msglog $RMAN_LOG_FILE append << EOF

RUN {
ALLOCATE CHANNEL ch02 TYPE 'SBT_TAPE'  parms 'ENV=(NB_ORA_POLICY=$NB_ORA_POLICY,NB_ORA_SCHED=Default-Application-Backup)';
BACKUP TAG ${BKPLOCATION}_INC1 filesperset 20 FORMAT 'arc_%d_%I_%T_%s_%t_%p' ARCHIVELOG ALL DELETE INPUT;
BACKUP TAG ${BKPLOCATION}_INC1 FORMAT 'ctrl_%d_%I_%T_%s_%t_%p' CURRENT CONTROLFILE;
RELEASE CHANNEL ch02;
}
EOF
"
fi

#---------------------------------------------------------------------------
#Initiate the command string
#--------------------------------------------------------------------------- 
if [ "$CUSER" = "root" ]
then
 su - $ORACLE_USER -c "$CMD_STR" >> $RMAN_LOG_FILE
 RSTAT=$?
else
 /usr/bin/sh -c "$CMD_STR" >> $RMAN_LOG_FILE
 RSTAT=$?
fi
 
# ---------------------------------------------------------------------------
# Log the completion of this script.
# ---------------------------------------------------------------------------
 
if [ "$RSTAT" = "0" ]
then
 LOGMSG="ended successfully"
else
 LOGMSG="ended in error"
fi
 

ELAPSED="(elapsed: $(($SECONDS / 3600))hrs $((($SECONDS / 60) % 60))min)"
echo >> $RMAN_LOG_FILE
echo Script $0 >> $RMAN_LOG_FILE
echo "==== $NB_ORA_PC_SCHED $LOGMSG on `date` $ELAPSED ====" >> $RMAN_LOG_FILE
echo >> $RMAN_LOG_FILE
 
exit $RSTAT
