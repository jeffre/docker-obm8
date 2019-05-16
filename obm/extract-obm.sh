#!/bin/bash

# this script's path
cd "$(dirname "${BASH_SOURCE[0]}")"

# purge old data
rm -rf afc.opt aua autoDiscovery.xml bin cb.opt \
  config.ini custom.xml home.txt jvm licenses \
  util version.txt 

sleep 1

function do_extract {
  mkdir -p "$2"
  tar xzOf obm-linux.tar.gz app.pkg/"$1" \
    | tar xzf - -C "$2"
}

do_extract jre-std-linux-amd64.tar.gz jvm
rm -rf \
  jvm/lib/amd64/libfontmanager.so \
  jvm/lib/amd64/libgstreamer-lite.so \
  jvm/lib/amd64/libjfxmedia.so \
  jvm/lib/amd64/libjfxwebkit.so \
  jvm/lib/fonts \
  jvm/lib/ext/jfxrt.jar \
  jvm/lib/images

do_extract app-common.tar.gz .
rm -rf \
  bin/help \
  bin/dropbox-core-sdk-3.0.3.1.jar \
  bin/microsoft-windowsazure-storage-sdk-6.0.0.1.jar \
  bin/google-api-client-1.19.1.jar \
  bin/google-api-services-drive-v2-rev158-1.19.1.jar \
  bin/google-oauth-client-1.19.0.jar \
  bin/google-http-client-jackson2-1.19.0.jar \
  bin/google-api-client-jackson2-1.19.1.jar \
  bin/dropbox-core-sdk-1.7.5.jar \
  bin/dropbox-core-sdk-3.0.3.jar \
  bin/microsoft-windowsazure-api-0.4.6.jar \
  bin/microsoft-windowsazure-storage-sdk-1.0.0.jar \
  bin/microsoft-windowsazure-storage-sdk-6.0.0.jar \
  bin/libFileSysUtilFbdX64.so \
  bin/libFileSysUtilObdX64.so \
  bin/libFileSysUtilSosX64.so \
  bin/libLotusBMLinX64.so \
  bin/libNixUtilFbdX64.so \
  bin/libNixUtilObdX64.so \
  bin/libNixUtilSosX64.so \
  bin/licenses
  
do_extract app-native-nix-x64.tar.gz .
find bin -maxdepth 1 -iname "lib*.so" \
  | grep -P "FbdX|Obd|Sos" \
  | xargs rm -f

do_extract app-nix-obm.tar.gz .
do_extract aua-common.tar.gz .
do_extract aua-native-nix-x64.tar.gz .
rm -rf \
  aua/lib/libFileSysUtilFbdX64.so \
  aua/lib/libFileSysUtilObdX64.so \
  aua/lib/libFileSysUtilSosX64.so \
  aua/lib/libNixUtilFbdX64.so \
  aua/lib/libNixUtilObdX64.so \
  aua/lib/libNixUtilSosX64.so

do_extract aua-nix-obm.tar.gz .

do_extract util-common.tar.gz .

do_extract util-nix-obm.tar.gz .

do_extract properties-common.tar.gz .
find bin/ -maxdepth 1 -type f -iname "*.properties" \
  | grep -v "_en\." \
  | xargs rm -f


do_extract app-inst-nix-obm.tar.gz .
rm -rf \
  termsofuse \
  bin/images \
  bin/splash.png \
  bin/scheduler-bsd \
  bin/RunConfigurator_QuickStartGuide.txt \
  bin/main_logo.png \
  bin/logo.png \
  bin/login_logo.png \
  bin/login_bg.png \
  bin/desktop.png \
  bin/cb.desktop \
  bin/about_logo.png \
  custom.xml \
  lookandfeel.xml

do_extract aua-inst-nix-obm.tar.gz .
find aua/lib -maxdepth 1 -type f -iname "*.properties" \
  | grep -v "_en\." \
  | xargs rm -f

