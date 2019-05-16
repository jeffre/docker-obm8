#!/bin/sh

# This is a script file to be executed after installation

# ------------------------- Retrieve APP_HOME ----------------------------------
APP_HOME=`pwd`
APP_BIN=${APP_HOME}/bin
UTIL_HOME=${APP_HOME}/util
AUA_HOME=${APP_HOME}/aua
USER_HOME=~

# ------------------------- Remove AUA ----------------------------------
if [ -f "$AUA_HOME/bin/shutdown.sh" ]; then
    cd "$AUA_HOME/bin"
    AUA_SCRIPT_NAME=obmaua

    ./shutdown.sh
    echo "Wait 5 seconds before AutoUpdateAgent exits"
fi

# Remove AutoUpdate service file
if [ -f "$UTIL_HOME/bin/remove-service.sh" ]; then
    echo "Removing AutoUpdate script $AUA_SCRIPT_NAME from service"
    "$UTIL_HOME/bin/remove-service.sh" $AUA_SCRIPT_NAME
fi

# ------------------------- Config application ----------------------------------
chmod +x "$UTIL_HOME/bin/taskkill"
echo "Changed file permission to +x for $UTIL_HOME/bin/taskkill"

chmod +x "$APP_BIN/Scheduler.sh"
echo "Changed file permission to +x for $APP_BIN/Scheduler.sh"

chmod +x "$APP_BIN/RunCB.sh"
echo "Changed file permission to +x for $APP_BIN/RunCB.sh"

chmod +x "$APP_BIN/shortcut.sh"
echo "Changed file permission to +x for $APP_BIN/shortcut.sh"

chmod +x "$APP_BIN/config.sh"
echo "Changed file permission to +x for $APP_BIN/config.sh"

cd "$APP_BIN"
"$APP_BIN/config.sh"

# -------------------- Install Shortcut ------------------------
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
