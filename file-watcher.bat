REM Windows Batch File-Wait Script 

REM http://danlinstedt.com/datavaultcat/windows-batch-file-wait-script/

REM Syntax:
REM CHECK 30 5 MyFile.txt

REM It will wait 30 seconds between “checking”, 
REM and will check for the file 5 times, then 
REM exit.

REM The Exit(0) is success, and the exit(-1) is 
REM the failure condition.

@Set Runtry=0
:START
@if exist %3 (
  @exit(0)
)
@sleep %1
@Set /A Runtry+=1
@if %Runtry% lss %2 goto :START
:ErrorOut
@echo %runtry% exiting
exit(-1)