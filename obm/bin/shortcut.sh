#!/bin/sh
RUN_CB='/usr/local/obm/bin/RunCB.sh'
case "`uname`" in
    Linux*) 
        dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
        if [ "$dist" = "Ubuntu" ]; then
            sudo -p "Please enter the root password: " -s "${RUN_CB}"
        else
            if [ `id -u` != "0" ]; then
                echo 'Please enter the root password' && su -s "${RUN_CB}"
            else 
                "${RUN_CB}"
            fi
        fi
        ;;
    *BSD*)  
        echo 'Please enter the root password' && su -m root -c "${RUN_CB}"
        ;;
    *)  
        echo "This OS `uname` is not supported by this script! Exit `basename $0` now!"
        ;;
esac
