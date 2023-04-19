REM kill all cloud drive

REM Google Drive
taskkill /F /IM GoogleDriveFs.exe

REM Dropbox
taskkill /F /IM Dropbox.exe
taskkill /F /IM DropboxUpdate.exe

REM OneDrive
taskkill /F /IM OneDrive.exe

REM Docker
docker stop jenkins
