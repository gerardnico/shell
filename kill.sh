#!/bin/sh

get_pid ()
{
    os_name=`uname -s`

    case "$os_name" in
	SunOS)
	    ANA_VARIANT="Solaris";;
	HP-UX)
	    ANA_VARIANT="HPUX";;
	AIX)
	    ANA_VARIANT="AIX";;
	Linux)
	    ANA_VARIANT="Linux";;
	CYGWIN_NT-5.*)
	    ANA_VARIANT="Windows";;
	*)
	    ANA_VARIANT="UnknownOS"
    esac

    if [ "$ANA_VARIANT" = "AIX" ]; then
    	echo `ps -u$LOGNAME | grep $1 | awk '{print $2}'` 
    elif [ "$ANA_VARIANT" = "Solaris" ]; then
        echo `/usr/ucb/ps -xww | grep $1 | grep -v grep | grep -v echo | awk '{print $1}'`
    else
    	echo `ps -u$LOGNAME | grep $1 | awk '{print $1}'` 
    fi
}

pid=`get_pid $1`
if test "$pid" ; then
    echo "Killing $1"
    kill -9 $pid
fi
exit 0
