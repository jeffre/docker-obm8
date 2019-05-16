#!/bin/sh

##############################  RunBackupSet.sh  ###############################
# You can use this shell script to run any of your backup sets from the        #
# command line. Just customize the "User Defined Section" below with your      #
# values for your backup action.                                               #
################################################################################

######################### START: User Defined Section ##########################

# --------------------------------- BACKUP_SET ---------------------------------
# | The name or ID of the backup set that you want to run                      |
# | If backup set name is not in English, please use ID instead.               |
# | e.g. BACKUP_SET="1119083740107"                                            |
# |  or  BACKUP_SET="FileBackupSet-1"                                          |
# |                                                                            |
# | You can leave this parameter blank if you have only 1 backup set.          |
# ------------------------------------------------------------------------------
BACKUP_SET=""

# -------------------------------- BACKUP_DESTS --------------------------------
# | The list of name or ID of the backup destinations that you want to run.    |
# | If backup destination name is not in English, please use ID instead.       |
# | e.g. BACKUP_DESTS="1740107119083"                                          |
# |  or  BACKUP_DESTS="Destination-1,Destination-2"                            |
# |  or  BACKUP_DESTS="ALL"                                                    |
# |                                                                            |
# | You can specify multiple destinations in comma-separated format,           |
# | or use "ALL" to run backup for all destinations.                           |
# ------------------------------------------------------------------------------
BACKUP_DESTS="ALL"

# -------------------------------- BACKUP_TYPE ---------------------------------
# | Set backup type. You don't need to change this if you are backing up a     |
# | file backup set.                                                           |
# | Options available: FILE/DATABASE/DIFFERENTIAL/LOG                          |
# | e.g. BACKUP_TYPE="FILE"          for file backup                           |
# |  or  BACKUP_TYPE="DATABASE"      for Full database backup                  |
# |  or  BACKUP_TYPE="DIFFERENTIAL"  for Differential database backup          |
# |  or  BACKUP_TYPE="LOG"           for Log database backup                   |
# ------------------------------------------------------------------------------
BACKUP_TYPE="FILE"

# -------------------------------- SETTING_HOME --------------------------------
# | Directory to your setting home.                                            |
# | Default to ${HOME}/.obm when not set.                                      |
# | e.g. SETTING_HOME="${HOME}/.obm"                                           |
# ------------------------------------------------------------------------------
SETTING_HOME=""

# --------------------------------- DELTA_MODE ---------------------------------
# | Set In-File Delta mode.                                                    |
# | Options available: Incremental/Differential/Full (I/D/F)                   |
# | e.g. DELTA_MODE="I"   for Incremental In-file delta backup                 |
# |  or  DELTA_MODE="D"   for Differential In-file delta backup                |
# |  or  DELTA_MODE="F"   for Full File backup                                 |
# |  or  DELTA_MODE=""    for using backup set in-file delta setting           |
# ------------------------------------------------------------------------------
DELTA_MODE=""

# -------------------------------- CLEANUP_MODE --------------------------------
# | You can enable Cleanup mode to remove obsolete files from your backup      |
# | destinations after backup.                                                 |
# | Options available: ENABLE-CLEANUP/DISABLE-CLEANUP                          |
# | e.g. CLEANUP_MODE="ENABLE-CLEANUP"                                         |
# |  or  CLEANUP_MODE="DISABLE-CLEANUP"                                        |
# ------------------------------------------------------------------------------
CLEANUP_MODE="DISABLE-CLEANUP"

# --------------------------------- DEBUG_MODE ---------------------------------
# | Set Debug mode.                                                            |
# | Options available: ENABLE-DEBUG/DISABLE-DEBUG                              |
# | e.g. DEBUG_MODE="ENABLE-DEBUG"                                             |
# |  or  DEBUG_MODE="DISABLE-DEBUG"                                            |
# ------------------------------------------------------------------------------
DEBUG_MODE="DISABLE-DEBUG"

########################## END: User Defined Section ###########################


################################################################################
#                S C R I P T                         U S A G E                 #
################################################################################

# Input Arguments will overwrite the above settings
# defined in 'User Defined Section'.
if [ $# -ge 1 ]; then

    if [ -n "$1" ]; then
        BACKUP_SET="$1"
    fi

fi

################################################################################
#          R E T R I E V E     A P P _ H O M E     P A T H                     #
################################################################################

EXE_DIR=`pwd`
SCRIPT_HOME=`dirname "$0"`
cd "$SCRIPT_HOME"
APP_BIN=`pwd`
APP_HOME=`dirname "$APP_BIN"`

################################################################################
#          R E T R I E V E     J A V A _ H O M E     P A T H                   #
################################################################################

if [ "Darwin" = `uname` ]; then
    JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
fi

if [ ! -x "$APP_HOME/jvm" ];
then
    echo "'$APP_HOME/jvm' does not exist!"
    if [ ! -n "$JAVA_HOME" ]; then
        echo "Please set JAVA_HOME!"
        exit 0
    else
        ln -sf "$JAVA_HOME" "$APP_HOME/jvm"
        if [ ! -x "$APP_HOME/jvm" ];
        then
            echo "Please create symbolic link for '$JAVA_HOME' to '$APP_HOME/jvm'"
            exit 0
        else
            echo "Created JAVA_HOME symbolic link at '$APP_HOME/jvm'"
        fi
    fi
fi

JAVA_HOME="$APP_HOME/jvm"
JAVA_EXE="$JAVA_HOME/bin/java"

# Verify the JAVA_EXE whether it can be executed or not.
if [ ! -x "${JAVA_EXE}" ]
then
    echo "The Java Executable file \"${JAVA_EXE}\" cannot be executed. Exit \""`basename "$0"`"\" now."
    exit 1
fi

# Verify the JAVA_EXE whether it is a valid JAVA Executable or not.
STRING_JAVA_VERSION="java version,openjdk version"
OUTPUT_JAVA_VERSION=`"${JAVA_EXE}" -version 2>&1`
OUTPUT_JVM_SUPPORT=0
BACKUP_IFS=$IFS
IFS=","
for word in $STRING_JAVA_VERSION; do
    if [ `echo "${OUTPUT_JAVA_VERSION}" | grep "${word}" | grep -cv "grep ${word}"` -le 0 ]
    then
      #echo "The Java Executable \"${JAVA_EXE}\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
      continue;
    else
      OUTPUT_JVM_SUPPORT=1
      break;
    fi
done
IFS=$BACKUP_IFS
if [ $OUTPUT_JVM_SUPPORT -eq 0 ]
then
    echo "The Java Executable \"${JAVA_EXE}\" is not a valid Java Executable. Exit \""`basename "$0"`"\" now."
    exit 1
fi

################################################################################
#            E X E C U T I O N     J A V A     P R O P E R T I E S             #
################################################################################

# Set LD_LIBRARY_PATH for Lotus Notes on Linux
if [ "Linux" = `uname` ];
then
    NOTES_PROGRAM=`cat "$APP_HOME/bin/notesenv"`
    LD_LIBRARY_PATH="$APP_HOME/bin:$NOTES_PROGRAM:$LD_LIBRARY_PATH"
    export NOTES_PROGRAM
else
    LD_LIBRARY_PATH="$APP_HOME/bin:$LD_LIBRARY_PATH"
fi

DEP_LIB_PATH="X64"
case "`uname -m`" in
    i[3-6]86)
        DEP_LIB_PATH="X86"
    ;;
esac
LD_LIBRARY_PATH="${APP_BIN}/${DEP_LIB_PATH}":".":"${LD_LIBRARY_PATH}"

SHLIB_PATH="$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH SHLIB_PATH

################################################################################
#                         J A V A     E X E C U T I O N                        #
################################################################################

# Change to APP_BIN for JAVA execution
cd "${APP_BIN}"

# Reference path will be used to avoid empty space in the parent directory
LIB_HOME=.
JAVA_OPTS="-Xrs -Xms128m -Xmx768m -XX:MaxDirectMemorySize=512m -client -Dsun.nio.PageAlignDirectMemory=true"
JNI_PATH="-Djava.library.path=$LIB_HOME"
CLASSPATH="$LIB_HOME:$LIB_HOME/cb.jar"
MAIN_CLASS=RunBackupSet

echo "-"
echo "Using APP_HOME      : $APP_HOME"
echo "Using SETTING_HOME  : $SETTING_HOME"
echo "Using JAVA_HOME     : $JAVA_HOME"
echo "Using JAVA_EXE      : $JAVA_EXE"
echo "Using JAVA_OPTS     : $JAVA_OPTS"
echo "Using JNI_PATH      : $JNI_PATH"
echo "Using CLASSPATH     : $CLASSPATH"
echo "-"

echo "Running Backup Set - '$BACKUP_SET' ..."

# API Arguments: RunBackupSet [APP_HOME] [BACKUP_SET] [BACKUP_DESTS] [BACKUP_TYPE] [SETTING_HOME] [DELTA_MODE] [CLEANUP_MODE] [DEBUG_MODE]

# Do not include double-quote for java options, jni path, classpath and
# main class.
# Only apply double-quote for path to java executable and execution arguments
"${JAVA_EXE}" $JNI_PATH -cp $CLASSPATH $JAVA_OPTS $MAIN_CLASS "${APP_HOME}" "${BACKUP_SET}" "${BACKUP_DESTS}" "${BACKUP_TYPE}" "${SETTING_HOME}" "${DELTA_MODE}" "${CLEANUP_MODE}" "${DEBUG_MODE}"

################################################################################
#                   R E S E T          A N D          E X I T                  #
################################################################################

cd "${EXE_DIR}"
exit 0
