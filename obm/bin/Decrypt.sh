#!/bin/sh

#################################  Decrypt.sh  #################################
# You can use this shell script to decrypt backup files using command-line.    #
# Just customize the "User Define Section" below with values for your decrypt  #
# action.                                                                      #
################################################################################

#########################  Start: User Defined Section  ########################

# -------------------------------  SOURCE_DIR  ---------------------------------
# | The path to the [<backup set ID>/blocks] folder which contains             |
# | the backup files that you want to decrypt.                                 |
# | This folder should located under backup destination physically.            |
# | e.g. SET SOURCE_DIR="/Users/john/backupdata/1498444438340/blocks"          |
# |      where directory "/Users/john/backupdata" is path of local destination |
# ------------------------------------------------------------------------------
SOURCE_DIR=""

# -------------------------------  ENCRYPT_KEY  --------------------------------
# | The encrypting key of the backup data.                                     |
# | e.g. SET ENCRYPT_KEY="RU5DUllQVF9LRVk="                                    |
# |                                                                            |
# | You can leave this parameter blank if backup data is not encrypted.        |
# ------------------------------------------------------------------------------
ENCRYPT_KEY=""

# -------------------------------  DECRYPT_TO  ---------------------------------
# | Directory to where you want files to be decrypted                          |
# | e.g. DECRYPT_TO="/tmp"                                                     |
# ------------------------------------------------------------------------------
DECRYPT_TO=""

# ------------------------------  DECRYPT_FROM  --------------------------------
# | File/Directory on the backup data that you would like to decrypt           |
# | e.g. DECRYPT_FROM="/Data"                                                  |
# ------------------------------------------------------------------------------
DECRYPT_FROM=""

# -----------------------------  POINT_IN_TIME  --------------------------------
# | The point-in-time snapshot (successful backup) that you want to decrypt    |
# | from the backup data. Use "Current" for the latest backup snapshot         |
# | e.g. POINT_IN_TIME="2006-10-04-12-57-13"                                   |
# |  or  POINT_IN_TIME="Current"                                               |
# |                                                                            |
# | You can retrieve the point in time by using the ListBackupJob.sh           |
# ------------------------------------------------------------------------------
POINT_IN_TIME="Current"

# --------------------------  RESTORE_PERMISSION  ------------------------------
# | set to "Y" if you want to restore file permissions                         |
# | set to "N" if you do NOT want to restore file permissions                  |
# ------------------------------------------------------------------------------
RESTORE_PERMISSION="N"

# ----------------------------  SKIP_INVALID_KEY  ------------------------------
# | set to "Y" if you want to skip decrypt file with invalid key               |
# | set to "N" if you want to prompt to input a correct key                    |
# ------------------------------------------------------------------------------
SKIP_INVALID_KEY="N"

# ------------------------------  SYNC_OPTION  ---------------------------------
# | Delete extra files                                                         |
# | set to "Y" if you want to enable sync option                               |
# | set to "N" if you do NOT want to enable sync option                        |
# | set to "" to prompt for selection                                          |
# ------------------------------------------------------------------------------
SYNC_OPTION="N"

# -------------------------  REPLACE_EXISTING_FILE  ----------------------------
# | set to "--all" to replace all existing file(s) of the same filename        |
# | set to "--none" to skip all existing file(s) with the same filename        |
# | set to "" to prompt for selection                                          |
# ------------------------------------------------------------------------------
REPLACE_EXISTING_FILE="--all"

# ------------------------------  SETTING_HOME  --------------------------------
# | Directory to your setting home. Log files will be located inside.          |
# | Default to ${HOME}/.obm when not set.                     |
# | e.g. SETTING_HOME="/Users/john/.obm"                      |
# ------------------------------------------------------------------------------
SETTING_HOME=""

# ---------------------------------  FILTER  -----------------------------------
# | Filter out what files you want to decrypt                                  |
# | -Pattern=xxx-Type=yyy-Target=zzz                                           |
# | where xxx is the filter pattern,                                           |
# |       yyy is the filter type, whice can be one of the following:           |
# |           [exact | exactMatchCase | contains | containsMatchCase|          |
# |            startWith | startWithMatchCase | endWith | endWithMatchCase]    |
# |       zzz is the filter target, which can be one of the following:         |
# |           [toFile | toFileDir | toDir]                                     |
# |                                                                            |
# | e.g. FILTER="-Pattern=.txt-Type=exact-Target=toFile"                       |
# ------------------------------------------------------------------------------
FILTER=""

# --------------------------------  TEMP_DIR  ----------------------------------
# | Directory to where you want to store decrypt files temporarily             |
# | e.g. TEMP_DIR="/tmp"                                                       |
# ------------------------------------------------------------------------------
TEMP_DIR=""

# -----------------------------  VERIFY_CHKSUM  --------------------------------
# | set to "Y" if you want to verify in-file delta file checksum during decrypt|
# | set to "N" if you do NOT want to verify in-file delta file checksum during |
# | decrypt                                                                    |
# ------------------------------------------------------------------------------
VERIFY_CHKSUM="N"

##########################  END: User Defined Section  #########################

################################################################################
#      R E T R I E V E            A P P _ H O M E           P A T H            #
################################################################################

EXE_DIR=`pwd`
SCRIPT_HOME=`dirname "$0"`
cd "$SCRIPT_HOME"
APP_BIN=`pwd`
APP_HOME=`dirname "$APP_BIN"`

################################################################################
#      R E T R I E V E           J A V A _ H O M E           P A T H           #
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
        echo "Created JAVA_HOME symbolic link at '$APP_HOME/jvm'"
    fi
fi

if [ ! -x "$APP_HOME/jvm" ];
then
    echo "Please create symbolic link for '$JAVA_HOME' to '$APP_HOME/jvm'"
    exit 0
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
#                  J A V A                 E X E C U T I O N                   #
################################################################################

# Set LD_LIBRARY_PATH for Lotus Notes on Linux
if [ "Linux" = `uname` ];
then
    NOTES_PROGRAM=`cat "$APP_BIN/notesenv"`
    LD_LIBRARY_PATH="$APP_BIN:$NOTES_PROGRAM:$LD_LIBRARY_PATH"
    export NOTES_PROGRAM
else
    LD_LIBRARY_PATH="$APP_BIN:$LD_LIBRARY_PATH"
fi

# The Decrypt Action must be execute at path $APP_HOME/bin
cd "${APP_BIN}"

DEP_LIB_PATH="X64"
case "`uname -m`" in
    i[3-6]86)
        DEP_LIB_PATH="X86"
    ;;
esac
LD_LIBRARY_PATH="${APP_BIN}/${DEP_LIB_PATH}":".":"${LD_LIBRARY_PATH}"

SHLIB_PATH="$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH SHLIB_PATH

# Reference path will be used to avoid empty space in the parent directory
LIB_HOME=.
JAVA_OPTS="-Xrs -Xms128m -Xmx768m -XX:MaxDirectMemorySize=512m -client -Dsun.nio.PageAlignDirectMemory=true"
JNI_PATH="-Djava.library.path=$LIB_HOME"
CLASSPATH="$LIB_HOME:$LIB_HOME/cb.jar"
MAIN_CLASS=Decrypt

echo "Using APP_HOME:          : ${APP_HOME}"
echo "Using SETTING_HOME:      : ${SETTING_HOME}"
echo "Using SOURCE_DIR         : ${SOURCE_DIR}"
echo "Using DECRYPT_FROM       : ${DECRYPT_FROM}"
echo "Using DECRYPT_TO         : ${DECRYPT_TO}"
echo "Using POINT_IN_TIME      : ${POINT_IN_TIME}"
echo "Using RESTORE_PERMISSION : ${RESTORE_PERMISSION}"
echo "Using TEMP_DIR           : ${TEMP_DIR}"

# Do not include double-quote for java options, jni path, classpath and
# main class.
# Only apply double-quote for path to java executable and execution arguments
"${JAVA_EXE}" $JAVA_OPTS $JNI_PATH -cp $CLASSPATH $MAIN_CLASS --to="${DECRYPT_TO}" --from="${DECRYPT_FROM}" --source-dir="${SOURCE_DIR}" --key="${ENCRYPT_KEY}" "${REPLACE_EXISTING_FILE}" --date="${POINT_IN_TIME}" --set-permission="${RESTORE_PERMISSION}" --skip-invalid-key="${SKIP_INVALID_KEY}" --sync="${SYNC_OPTION}" --filter="${FILTER}" --temp-dir="${TEMP_DIR}" --verify-delta-file-chksum="${VERIFY_CHKSUM}" --app-home="${APP_HOME}" --setting-home="${SETTING_HOME}"

################################################################################
#                   R E S E T          A N D          E X I T                  #
################################################################################

cd "${EXE_DIR}"
exit 0
