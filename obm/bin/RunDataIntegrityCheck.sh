#!/bin/sh

##########################  RunDataIntegrityCheck.sh  ##########################
# You can use this shell script to run any of your backup sets from the        #
# command line. Just customize the "User Defined Section" below with your      #
# values for your backup action.                                               #
################################################################################

########################  START: User Defined Section  #########################

# -------------------------- SETTING_HOME (Optional) ---------------------------
# | Directory to your setting home.                                            |
# | Default to ${HOME}/.obm when not set.                                      |
# | e.g. SETTING_HOME="${HOME}/.obm"                                           |
# ------------------------------------------------------------------------------
SETTING_HOME=""

# --------------------------------- BACKUP_SET ---------------------------------
# | The name or ID of the backup set that you want to run.                     |
# | If backup set name is not in English, please use ID instead.               |
# | e.g. BACKUP_SET="1119083740107"                                            |
# |  or  BACKUP_SET="FileBackupSet-1"                                          |
# | You can use "ALL" to run data integrity check for all backup sets.         |
# | i.e. BACKUP_SET="ALL"                                                      |
# |                                                                            |
# | You can leave this parameter blank if you have only 1 backup set.          |
# ------------------------------------------------------------------------------
BACKUP_SET="ALL"

# -------------------------------- BACKUP_DEST ---------------------------------
# | The name or ID of the backup destination that you want to run.             |
# | If backup destination name is not in English, please use ID instead.       |
# | e.g. BACKUP_DEST="1740107119083"                                           |
# |  or  BACKUP_DEST="Destination-1"                                           |
# | You can use "ALL" to run data integrity check for all destinations.        |
# | i.e. BACKUP_DEST="ALL"                                                     |
# |                                                                            |
# | You can leave this parameter blank if you have only 1 destination.         |
# | Remark: This option is ignored if BACKUP_SET="ALL"                         |
# ------------------------------------------------------------------------------
BACKUP_DEST="ALL"

# ---------------------------------- CRC_MODE ----------------------------------
# | You can run Cyclic Redundancy Check (CRC) during data integrity check      |
# | Options available: ENABLE-CRC/DISABLE-CRC                                  |
# | i.e. CRC_MODE="ENABLE-CRC"                                                 |
# |  or  CRC_MODE="DISABLE-CRC"                                                |
# ------------------------------------------------------------------------------
CRC_MODE="DISABLE-CRC"

# -------------------------------  REBUILD_MODE  -------------------------------
# | You can run rebuild index                                                  |
# | Options available: ENABLE-REBUILD/DISABLE-REBUILD                          |
# | i.e. REBUILD_MODE="ENABLE-REBUILD"                                         |
# |  or  REBUILD_MODE="DISABLE-REBUILD"                                        |
# ------------------------------------------------------------------------------
REBUILD_MODE="DISABLE-REBUILD"

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
MAIN_CLASS=RunDataIntegrityCheck

echo "-"
echo "Using APP_HOME      : $APP_HOME"
echo "Using SETTING_HOME  : $SETTING_HOME"
echo "Using JAVA_HOME     : $JAVA_HOME"
echo "Using JAVA_EXE      : $JAVA_EXE"
echo "Using JAVA_OPTS     : $JAVA_OPTS"
echo "Using JNI_PATH      : $JNI_PATH"
echo "Using CLASSPATH     : $CLASSPATH"
echo "-"

echo "Running data integrity check for backup set - '$BACKUP_SET', destination - '$BACKUP_DEST' ..."

# API Arguments: RunDataIntegrityCheck [APP_HOME] [SETTING_HOME] [BACKUP_SET] [BACKUP_DEST] [CRC_MODE] [REBUILD_MODE]

# Do not include double-quote for java options, jni path, classpath and
# main class.
# Only apply double-quote for path to java executable and execution arguments
"${JAVA_EXE}" $JNI_PATH -cp $CLASSPATH $JAVA_OPTS $MAIN_CLASS "${APP_HOME}" "${SETTING_HOME}" "${BACKUP_SET}" "${BACKUP_DEST}" "${CRC_MODE}" "${REBUILD_MODE}"

################################################################################
#                   R E S E T          A N D          E X I T                  #
################################################################################

cd "${EXE_DIR}"
exit 0
