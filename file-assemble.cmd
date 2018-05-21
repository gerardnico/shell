@echo off
echo Assembling the Virtual Box images for OTN Virtual Developer Day
echo.
echo Producing VDD_WLS_labs_2012.ova from VDD_WLS_labs_2012.1 - VDD_WLS_labs_2012.6
echo.
copy /B VDD_WLS_labs_2012.ova.1 + VDD_WLS_labs_2012.ova.2 + VDD_WLS_labs_2012.ova.3 + VDD_WLS_labs_2012.ova.4 + VDD_WLS_labs_2012.ova.5 + VDD_WLS_labs_2012.ova.6 VDD_WLS_labs_2012.ova
echo.
dir *.ova
echo.
echo Done