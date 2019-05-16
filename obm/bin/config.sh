#!/bin/sh

# ------------------------- Retrieve APP_HOME ----------------------------------
cd `dirname "$0"`
APP_BIN=`pwd`
APP_HOME=`dirname "$APP_BIN"`
UTIL_HOME="${APP_HOME}/util"

# -------------------- Print Logging Message Header ----------------------------
echo "Log Time: `date`"

# ------------ Verify if the privilege is enough for install ------------------
## Verify the privilege if the shell script "privilege.sh" exist.
if [ -z "$1" ]; then
echo ""
if [ -f "$UTIL_HOME/bin/privilege.sh" ]
then
  echo "Verifying current user privilege ..."
  "$UTIL_HOME/bin/privilege.sh" "config"
  [ $? -ne 0 ] && echo "Exit \"`basename $0`\" now!" && exit 1
else
  echo "The shell script \"$UTIL_HOME/bin/privilege.sh\" is missing."
  echo "Exit \"`basename $0`\" now!" && exit 1
fi
echo "Current user has enough privilege to \"config\"."
echo ""
fi

# -------------------- Print Logging Message  ----------------------------------

OS_IS_LINUX=0

case "`uname`" in
  Linux*)
    echo "Start configuration on Generic Linux Platform (`uname`)"
    OS_IS_LINUX=1
    ;;
  Solaris*) echo "Start configuration on Solaris 2.X Platform (`uname`)";;
  SunOS*)   echo "Start configuration on Solaris 5.X Platform (`uname`)";;
  *BSD*)    echo "Start configuration on BSD distribution Platform (`uname`)";;
  **)       echo "This OS `uname` is not supported by this script! Exit `basename $0` now!"
      exit 1 ;;
esac

echo ""
echo "Installation Path: ${APP_HOME}"

# ----------------------- Configure Application --------------------------------
# Get the JAVA Home path.
cd "${APP_HOME}"

# Verify the JAVA_EXE whether it is a valid JAVA Executable or not.
STRING_JAVA_VERSION="java version,openjdk version"
OUTPUT_JAVA_VERSION=`"${APP_HOME}/jvm/bin/java" -version 2>&1`
OUTPUT_JVM_SUPPORT=0
BACKUP_IFS=$IFS
IFS=","
for word in $STRING_JAVA_VERSION; do
    if [ `echo "${OUTPUT_JAVA_VERSION}" | grep "${word}" | grep -cv "grep ${word}"` -le 0 ]
    then
      #echo "The Java Executable \"${APP_HOME}/jvm/bin/java\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
      continue;
    else
      OUTPUT_JVM_SUPPORT=1
      break;
    fi
done
IFS=$BACKUP_IFS
if [ $OUTPUT_JVM_SUPPORT -eq 0 ]
then
    echo "The Java Executable \"${APP_HOME}/jvm/bin/java\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
    exit 1
fi

# Verify if the JVM version in the JVM Home are supported
MINIMUM_SUPPORTED_JVM_VERSION=1.7 # The JVM supported Version is defined in APP v7.0 onwards.
MAXIMUM_SUPPORTED_JVM_VERSION=1.8 # The JVM supported Version is defined in APP v7.0 onwards.
echo "Minimum supported JVM version: $MINIMUM_SUPPORTED_JVM_VERSION"
echo "Maximum supported JVM version: $MAXIMUM_SUPPORTED_JVM_VERSION"
[ ! -f "$UTIL_HOME/bin/verify-jvm-version.sh" ] && echo "The shell script \"$UTIL_HOME/bin/verify-jvm-version.sh\" is missing." && echo "Exit \"`basename $0`\" now!" && exit 1
"$UTIL_HOME/bin/verify-jvm-version.sh" "$APP_HOME/jvm" "$MINIMUM_SUPPORTED_JVM_VERSION" "$MAXIMUM_SUPPORTED_JVM_VERSION" 1>"/dev/null" 2>&1
if [ $? -ne 0 ]
then
    [ -L "$APP_HOME/jvm" ] && rm -f "$APP_HOME/jvm" && echo "Removed the Symlink \"$APP_HOME/jvm\"."
    echo "The JVM version is out of range \"$MINIMUM_SUPPORTED_JVM_VERSION\" - \"$MAXIMUM_SUPPORTED_JVM_VERSION\" which is not supported by the APP."
    echo "Please change the JAVA_HOME Directory and run the installation again."
    echo "Exit \"`basename $0`\" now!"
    exit 1
fi

echo "Current JVM version is supported for installation."
if [ ! -x "$APP_HOME/jvm/bin/bJW" ]; then
    echo "Create Backup Manager JVM, Path: $APP_HOME/jvm/bin/bJW"
    ln -sf "$APP_HOME/jvm/bin/java" "$APP_HOME/jvm/bin/bJW"
    chmod 755 "$APP_HOME/jvm/bin/bJW"
fi

if [ ! -x "$APP_HOME/jvm/bin/bschJW" ]; then
    echo "Create Scheduler Service JVM, Path: $APP_HOME/jvm/bin/bschJW"
    ln -sf "$APP_HOME/jvm/bin/java" "$APP_HOME/jvm/bin/bschJW"
    chmod 755 "$APP_HOME/jvm/bin/bschJW"
fi

# Set File Permission
echo "Setup File Permissions"
touch "$APP_HOME/home.txt"
chmod 777 "$APP_HOME/home.txt"
chmod 755 $APP_BIN/*
chmod 777 "$APP_BIN/notesenv"
chmod 755 $UTIL_HOME/*

exit 0
