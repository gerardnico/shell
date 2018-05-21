#!/bin/bash
# Just to open explorer to the current directory
# First Parameter, the path to open
# See https://cygwin.com/cygwin-ug-net/using-effectively.html

if [ -z ${1+x} ]; then 
    path_to_open=$PWD; 
else 
    path_to_open=$1;
fi

/c/Windows/System32/explorer.exe $(cygpath -w $path_to_open)