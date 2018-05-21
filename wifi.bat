@echo off
REM Script to enable or disable the wifi
echo.

:argcheck
if /I "%1" == "disabled" goto :check_Permissions 
if /I "%1" == "enabled" goto :check_Permissions 
if /I "%1." == "." echo The first argument must be given.

:syntax
echo The syntax of the command is
echo ------------------------------------
echo   wifi option
echo ------------------------------------
echo where option is one of:
echo     - enabled
echo     - disabled
echo.
echo Example:
echo   wifi disabled
goto end


:check_Permissions
echo The first agrument %%1 is set with the value: %1
echo Administrative permissions required. Detecting permissions...

net session >nul 2>&1
if %errorLevel% == 0 (
	echo Success: Administrative permissions confirmed.
) else (
	echo Failure: Current permissions inadequate. 
	echo The current script must be run as administrator.
	goto end
)


:wifi
if /I "%1" == "disabled" (
	netsh interface set interface name="Wireless Network Connection" admin=DISABLED
) else (
	netsh interface set interface name="Wireless Network Connection" admin=enabled
)

pause >null

:end