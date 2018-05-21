:: This script open a browser to the docker-machine host port
:: Parmeter the port
:: 
:: Syntax:
:: 
::     browse-docker.bat port
::
:: Example:
::
::     browse-docker.bat 3000
::

@SET SCRIPT_PATH=%~dp0
@echo Getting the docker-machine ip
@for /f "delims=" %%a in ('docker-machine ip') do @set DOCKER_MACHINE_IP=%%a
@SET DOCKER_URL=http://%DOCKER_MACHINE_IP%:%1
@echo Going to %DOCKER_URL%
@%SCRIPT_PATH%\browse.bat %DOCKER_URL%
