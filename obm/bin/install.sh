#!/bin/sh

# ------------------------- Retrieve APP_HOME ----------------------------------
cd `dirname "$0"`
APP_BIN=`pwd`
APP_HOME=`dirname "$APP_BIN"`
UTIL_HOME=${APP_HOME}/util
#AUA_HOME=${APP_HOME}/aua
AUA_BIN=${AUA_HOME}/bin
USER_HOME=~

# -------------------- Print Logging Message Header ----------------------------
echo "Log Time: `date`"
# ----------------------- Verify if JVM home exist --------------------------------
JVM_HOME=${APP_HOME}/jvm
if [ ! -d "$JVM_HOME" ]; then
    echo "$JVM_HOME does not exist! Please copy your java 1.7 to $JVM_HOME"
    exit 1
fi

# ------------ Verify if the privilege is enough for install ------------------
## Verify the privilege if the shell script "privilege.sh" exist.
if [ -z "$1" ]; then
    echo ""
    if [ -f "$UTIL_HOME/bin/privilege.sh" ]; then
        echo "Verifying current user privilege ..."
        "$UTIL_HOME/bin/privilege.sh" "install"
        [ $? -ne 0 ] && echo "Exit \"`basename $0`\" now!" && exit 1
    else
        echo "The shell script \"$UTIL_HOME/bin/privilege.sh\" is missing."
        echo "Exit \"`basename $0`\" now!" && exit 1
    fi
    echo "Current user has enough privilege to \"install\"."
    echo ""
fi
# -------------------- Print Logging Message -----------------------------------

case "`uname`" in
    Linux*)   echo "Start installation on Generic Linux Platform (`uname`)";;
    Solaris*) echo "Start installation on Solaris 2.X Platform (`uname`)";;
    SunOS*)   echo "Start installation on Solaris 5.X Platform (`uname`)";;
    *BSD*)    echo "Start installation on BSD distribution Platform (`uname`)";;
    **)       echo "This OS `uname` is not supported by this script! Exit `basename $0` now!"
              exit 0 ;;
esac

echo ""

echo "Installation Path: ${APP_HOME}"

# ----------------------- Configure Application --------------------------------
cd "$APP_BIN"
echo "Configure Application Path: ${APP_HOME}"
./config.sh $1 1>config.log 2>&1

[ $? -ne 0 ] && echo "" && echo "Error is found during \"config\"." && echo "Please read the file \"`pwd`/config.log\" for more information." && echo "\"Exit \"`basename $0`\" now!" && exit 1
# ------------------------- Install Scheduler ----------------------------------
echo "Installing Scheduler Service"
SCH_SCRIPT_PATH=${APP_BIN}
SCH_SCRIPT_NAME="obmscheduler"

cd "${APP_BIN}"

# Create the service script
case "`uname`" in
    Linux*)   SCH_SCRIPT_SRC=scheduler ;;
    Solaris*) SCH_SCRIPT_SRC=scheduler ;;
    SunOS*)   SCH_SCRIPT_SRC=scheduler ;;
    OpenBSD*) SCH_SCRIPT_SRC=scheduler-openbsd ;;
    *BSD*)    SCH_SCRIPT_SRC=scheduler-bsd ;;
    **)       echo "This OS `uname` is not supported by this script! Exit `basename $0` now!"
              exit 0 ;;
esac

sed "s|@sed.script.name@|${SCH_SCRIPT_NAME}|g" <./${SCH_SCRIPT_SRC} | sed "s|@sed.product.home@|${APP_HOME}|g" > ./${SCH_SCRIPT_NAME}

echo "Scheduler Service Script created at ${APP_BIN}/${SCH_SCRIPT_NAME}"

"${UTIL_HOME}/bin/install-service.sh" "${SCH_SCRIPT_PATH}/${SCH_SCRIPT_NAME}"

# -------------------------- Startup Services ----------------------------------
echo "Run Scheduler Service"
sh "${APP_BIN}/Scheduler.sh" &
echo "Started Scheduler Service"

# Install Shortcut

# sed expression to replace every occurances of ${VAR_NAME}=/.../<filename> to ${VAR_NAME}=${APP_BIN}/<filename>
getSEDUpdateAppBinExpression() {
    VAR_NAME="$1"
    case "`uname`" in
        Linux*)
            VAR_DIST=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
            if [ "$VAR_DIST" = "Ubuntu" ]; then
                echo "s:(^${VAR_NAME}=[^/]*).*/([^/]*)$:\\\1${APP_BIN}/\\\2:g"
            else
                echo "s:(^${VAR_NAME}=[^/]*).*/([^/]*)$:\1${APP_BIN}/\2:g"
            fi
            ;;
        *)
            echo "s:(^${VAR_NAME}=[^/]*).*/([^/]*)$:\1${APP_BIN}/\2:g"
            ;;
    esac
}

# update app directory in shortcut-related file
# note that sed -i cannot be used here because some nix system doesn't support this option (e.g. OpenBSD)
# therefore, sed result must be written to temp first before overwrite target file
updateShortcutAppDir() {
    SED_REGEXTEND_OPT="$1"
    SED_TMP="${APP_BIN}/sed_tmp"
    # update app directory of RUN_CB field in shortcut target file
    sed "${SED_REGEXTEND_OPT}" "$(getSEDUpdateAppBinExpression RUN_CB)" "${APP_BIN}/shortcut.sh">"${SED_TMP}"
    # avoid alias of cp to prevent permission copy from temp to target
    /bin/cp "${SED_TMP}" "${APP_BIN}/shortcut.sh"
    # update app directory of Exec and Icon field in shortcut file
    sed "${SED_REGEXTEND_OPT}" -e "$(getSEDUpdateAppBinExpression Exec)" -e "$(getSEDUpdateAppBinExpression Icon)" "${APP_BIN}/cb.desktop">"${SED_TMP}"
    # avoid alias of cp to prevent permission copy from temp to target
    /bin/cp "${SED_TMP}" "${APP_BIN}/cb.desktop"
    rm -f "${SED_TMP}"
}

case "`uname`" in
    Linux*)
        updateShortcutAppDir "-r"
        if [ -d "/usr/share/applications" ]; then
            echo "Create Shortcut to /usr/share/applications"
            cp "$APP_BIN/cb.desktop" "/usr/share/applications/obm.desktop"
        fi
        if [ -d "$USER_HOME/Desktop" ]; then
            echo "Create Shortcut to $USER_HOME/Desktop"
            cp "$APP_BIN/cb.desktop" "$USER_HOME/Desktop/obm.desktop"
        fi
        ;;
    *BSD*)
        updateShortcutAppDir "-E"
        if [ -d "/usr/local/share/applications" ]; then
            echo "Create Shortcut to /usr/local/share/applications"
            cp "$APP_BIN/cb.desktop" "/usr/local/share/applications/obm.desktop"
        fi
        if [ -d "$USER_HOME/Desktop" ]; then
            echo "Create Shortcut to $USER_HOME/Desktop"
            cp "$APP_BIN/cb.desktop" "$USER_HOME/Desktop/obm.desktop"
        fi
        ;;
    *)
        ;;
esac
# rm "$APP_BIN/cb.desktop"
exit 0
