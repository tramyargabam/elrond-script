@echo off
@title:Building Elrond Node
setlocal EnableDelayedExpansion
color 0a

::Find Git if installed in the system ,if not install Git
where git.exe >nul 2>nul
IF ERRORLEVEL 1 ( 
	IF NOT EXIST "%PROGRAMDATA%\chocolatey\bin\choco.exe" @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
	echo Git is not installed in the system, installing now....
	choco install git
)

::Find Go if installed in the system ,if not install Go
where go.exe >nul 2>nul
IF ERRORLEVEL 1 ( 
	IF NOT EXIST "%PROGRAMDATA%\chocolatey\bin\choco.exe" @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
	echo Go is not installed in the system, installing now....
	choco install golang
)

:: Refresh Enviroment without exiting the cmd
call refreshenv.cmd

:: Check version of Git and Go
echo Git is installed, checking version :
git --version
echo Go is installed, checking version :
go version

:: Node Build Script by Elrond
cd %userprofile%

SET BINTAG=v1.0.40
SET CONFTAG= BoN-ph2-w1
SET DIR=%~dp0%

:: Create Paths
if not exist "%GOPATH%\src\github.com\ElrondNetwork" mkdir %GOPATH%\src\github.com\ElrondNetwork
cd %GOPATH%\src\github.com\ElrondNetwork

:: Delete previously cloned repos
if exist "%GOPATH%\src\github.com\ElrondNetwork\elrond-go" @RD /S /Q "%GOPATH%\src\github.com\ElrondNetwork\elrond-go"
if exist "%GOPATH%\src\github.com\ElrondNetwork\elrond-config" @RD /S /Q "%GOPATH%\src\github.com\ElrondNetwork\elrond-config"

:: Clone elrond-go & elrond-config repos
git clone --branch %BINTAG% https://github.com/ElrondNetwork/elrond-go
git clone --branch %CONFTAG% https://github.com/ElrondNetwork/elrond-config

cd %GOPATH%\src\github.com\ElrondNetwork\elrond-config
copy /Y *.* %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node\config

:: Build the node executable
cd %GOPATH%\pkg\mod\cache
del /s *.lock
cd %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node
SET GO111MODULE=on
go mod vendor
go build -i -v -ldflags="-X main.appVersion=%BINTAG%"

:: Build the key generator & run it
cd %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\keygenerator
go build
keygenerator.exe

:: Copy keys in their proper place & in backup location
copy /Y initialBalancesSk.pem %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node\config
copy /Y initialNodesSk.pem %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node\config

mkdir %userprofile%\node-pem-backup
copy /Y initialBalancesSk.pem %userprofile%\node-pem-backup
copy /Y initialNodesSk.pem %userprofile%\node-pem-backup
cls
:: Name your node
set /P nodename=What is your desired name for your Node?
(
echo [Preferences]
echo     # NodeDisplayName represents the friendly name a user can pick for his node in the status monitor
echo       NodeDisplayName = "%nodename%"
)>"%GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node\config\prefs.toml"

:: Creating a script to run again your node
( 
echo @echo off
echo cd %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node
echo node.exe
)> "%DIR%\runyournode.cmd"

:: Run your Node Y/N
:choice
set /P c=You want to run your node[Y/N]?
if /I "%c%" EQU "Y" goto :yes
if /I "%c%" EQU "N" goto :no
goto :choice

:yes 
cd %GOPATH%\src\github.com\ElrondNetwork\elrond-go\cmd\node
node.exe

:no 
timeout 3
