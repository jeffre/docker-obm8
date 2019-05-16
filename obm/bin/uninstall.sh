#!/bin/sh

# ------------------------- Retrieve APP_HOME ----------------------------------
cd `dirname "$0"`
APP_BIN=`pwd`
APP_HOME=`dirname $APP_BIN`
JVM_BIN=$APP_HOME/jvm/bin
UTIL_HOME=${APP_HOME}/util
AUA_HOME=$APP_HOME/aua
USER_HOME=~
# ------------ Print Logging Message Header ------------------------------------
echo "Log Time: `date`"
# ------------ Verify if the privilege is enough for uninstall ----------------
## Verify the privilege if the shell script "privilege.sh" exist.
if [ -z "$1" ]; then
echo ""
if [ -f "$UTIL_HOME/bin/privilege.sh" ]
then
  echo "Verifying current user privilege ..."
  "$UTIL_HOME/bin/privilege.sh" "uninstall"
  [ $? -ne 0 ] && echo "Exit \"`basename $0`\" now!" && exit 1
else
  echo "The shell script \"$UTIL_HOME/bin/privilege.sh\" is missing."
  echo "Exit \"`basename $0`\" now!" && exit 1
fi
echo "Current user has enough privilege to \"uninstall\"."
echo ""
fi
# ------------------------- Uninstall Procedure --------------------------------

# Print Logging Message Header
echo "Uninstall KeepItSafe from $APP_HOME"
echo ""

cd "$APP_BIN"
SCH_SCRIPT_NAME="obmscheduler"

if [ -d "$APP_HOME/ipc/Scheduler" ];
then
  if [ -f "$APP_HOME/ipc/Scheduler/running" ];
  then
    echo "Shutting down Scheduler"
    touch "$APP_HOME/ipc/Scheduler/stop"
    echo "Wait 5 seconds before Scheduler exits"
    sleep 5
  fi
fi


if [ -f "$UTIL_HOME/bin/taskkill" ];
then
    echo "Kill running KeepItSafe"
    sh "$UTIL_HOME/bin/taskkill" "$JVM_BIN/bJW"
    sh "$UTIL_HOME/bin/taskkill" "$JVM_BIN/bschJW"
    sh "$UTIL_HOME/bin/taskkill" "$JVM_BIN/java"
fi
# Remove Scheduler service file
echo "Removing Scheduler script $SCH_SCRIPT_NAME from service"
"$UTIL_HOME/bin/remove-service.sh" $SCH_SCRIPT_NAME

# -------------------------- Finished Uninstallation ---------------------------
if [ -f "/usr/share/applications/obm.desktop" ]
then
echo "Remove shortcut /usr/share/applications/obm.desktop"
rm "/usr/share/applications/obm.desktop"
fi

if [ -f "$USER_HOME/Desktop/obm.desktop" ]
then
echo "Remove shortcut $USER_HOME/Desktop/obm.desktop"
rm "$USER_HOME/Desktop/obm.desktop"
fi

USER_HOME=~
case "`uname`" in
    Linux*)
        if [ -f "/usr/share/applications/obm.desktop" ]; then
            echo "Remove shortcut /usr/share/applications/obm.desktop"
            rm "/usr/share/applications/obm.desktop"
        fi
        if [ -f "$USER_HOME/Desktop/obm.desktop" ]; then
            echo "Remove shortcut $USER_HOME/Desktop/obm.desktop"
            rm "$USER_HOME/Desktop/obm.desktop"
        fi
        ;;
    *BSD*)
        if [ -f "/usr/local/share/applications/obm.desktop" ]; then
            echo "Remove shortcut /usr/local/share/applications/obm.desktop"
            rm "/usr/local/share/applications/obm.desktop"
        fi
        if [ -f "$USER_HOME/Desktop/obm.desktop" ]; then
            echo "Remove shortcut $USER_HOME/Desktop/obm.desktop"
            rm "$USER_HOME/Desktop/obm.desktop"
        fi
        ;;
    *)
        ;;
esac

echo "KeepItSafe uninstall procedure is complete!"
echo "It is now safe to remove files from $APP_HOME"

exit 0
