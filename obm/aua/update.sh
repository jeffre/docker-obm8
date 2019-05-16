#!/bin/sh
APP_JVM_HOME="../jvm"
AUA_JVM_HOME="./jvm"
JVM_HOME="$APP_JVM_HOME"

if [ "$4" = "MIGRATE" ]; then
    JVM_HOME="$AUA_JVM_HOME"
else
    # add to support define JVM home on java
    if [ ! -z "$4" ]; then
        JVM_HOME="$4"
    fi
fi

if [ -f "$JVM_HOME/bin/javau" ]; then 
    echo "javau exists. Continue update." 
else 
    # copy java as javau to distinguish update process and other processes
    cp "$JVM_HOME/bin/java" "$JVM_HOME/bin/javau" 
    echo "javau added, continue update."
fi

JAVA_EXE="$JVM_HOME/bin/javau"

LIB_HOME="./lib"
JAVA_OPTS="-Xrs -Xmx128m"
JNI_PATH="-Djava.library.path=$LIB_HOME"
# AuaI need jdom.jar because Xml classes likes ConfigXML use jdom to parse xml
CLASSPATH="$LIB_HOME:$LIB_HOME/aua.jar:$LIB_HOME/bcmail-jdk15on-1.51.jar:$LIB_HOME/bcpkix-jdk15on-1.51.jar:$LIB_HOME/bcprov-jdk15on-151.jar:$LIB_HOME/commons-logging-1.1.3.jar:$LIB_HOME/httpclient-4.3.5.jar:$LIB_HOME/httpcore-4.3.2.jar:$LIB_HOME/jackson-core-asl-1.9.13.jar:$LIB_HOME/jackson-mapper-asl-1.9.13.jar:$LIB_HOME/jdom.jar:$LIB_HOME/jersey-apache-client4-1.18.1.jar:$LIB_HOME/jersey-bundle-1.18.1.jar:$LIB_HOME/jersey-multipart-1.18.1.jar:$LIB_HOME/log4j.jar:$LIB_HOME/org.json-20150730.jar"
MAIN_CLASS=AuaI
"$JAVA_EXE" "$JAVA_OPTS" "$JNI_PATH" -cp "$CLASSPATH" "$MAIN_CLASS" "$1" "$2" > ../log/Update.log
if [ "$?" != "0" ]; then
    exit
fi
if [ "$3" = "UI" ]; then
    sh "../bin/RunCB.sh"
fi
exit
