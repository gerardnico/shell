@echo off
if "%1"=="" GOTO USAGE
copy %1 %2 %3 %4 %5 %6 %7 %8 %9
GOTO END
:USAGE
copy /?
:END