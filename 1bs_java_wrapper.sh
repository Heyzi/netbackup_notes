#!/bin/sh
SERVICE_NAME="app"
APP_PATH="/app/app"
JAR_FILE="$APP_PATH/monitoring.jar"
COMMAND_LINE="--spring.config.location=$APP_PATH/user.properties"
PID_PATH_NAME="$APP_PATH/$SERVICE_NAME.pid"
LOG_FILE="$APP_PATH/logs/log.out"
JAVA_PATH="/usr/bin/java"
USERNAME="mon"
TIMEOUT="20"

function proc_test {
        if [ ! -f $PID_PATH_NAME ]; then
                        echo "$SERVICE_NAME was normally stopped last time... No PID file"
						else

                        if [ -n "$(ps -p $(cat $PID_PATH_NAME) -o pid=)" ]; then
                                echo "$SERVICE_NAME is running... "
                        else
                                echo "$SERVICE_NAME is crashed last time..."
                                echo "Delete PID file and try again $PID_PATH_NAME"
                        fi

        fi
}
function proc_start {
            echo "Starting $SERVICE_NAME ..."
            sudo -u $USERNAME nohup $JAVA_PATH -jar $JAR_FILE $COMMAND_LINE  >> $LOG_FILE 2>&1&
            echo $! > $PID_PATH_NAME
            sleep $TIMEOUT
}
function proc_stop {
            PID=$(cat $PID_PATH_NAME);
            echo "$SERVICE_NAME stopping ...";
            kill $PID;
            echo "$SERVICE_NAME stopped ...";
            rm $PID_PATH_NAME
}

case $1 in
    start)
        if [ ! -f $PID_PATH_NAME ]; then
                        proc_start
                        proc_test
        else
            proc_test
        fi
    ;;
    stop)
        if [ -f $PID_PATH_NAME ]; then
                        proc_stop
                        else
            proc_test
        fi
    ;;
    restart)
        if [ -f $PID_PATH_NAME ]; then
                        proc_stop
                        proc_start
                        proc_test
        else
            proc_test
        fi
    ;;
        status)
          proc_test
    ;;
esac
