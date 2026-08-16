@echo off
setlocal EnableExtensions

if /i "%~1"=="help" goto :usage
if /i "%~1"=="-h" goto :usage
if /i "%~1"=="/?" goto :usage
if /i "%~1"=="-help" goto :usage
if /i "%~1"=="--help" goto :usage

if not "%~1"=="" (
    echo ERROR: Incorrect command argument "%~1".
    echo This script does not take arguments.
    goto :usage
)

echo Stopping Infinity Battlescape client...
call "%~dp0kill_client.bat"
echo.
echo Stopping Infinity Battlescape server...
call "%~dp0kill_server.bat"
exit /b 0

:usage
echo.
echo Usage: %~nx0
echo.
echo Stop the local IB client and server processes.
echo Incorrect arguments abort without killing a process.
exit /b 1
