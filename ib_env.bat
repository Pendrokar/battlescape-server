@echo off
REM Shared Infinity Battlescape paths and local-server defaults.
REM Call from other scripts:  call "%~dp0ib_env.bat"
REM Do not use setlocal here — variables must remain in the caller.

set "IB_ROOT=C:\Program Files (x86)\Steam\steamapps\common\Infinity Battlescape"
set "IB_BIN=%IB_ROOT%\Bin"
set "IB_EXE=%IB_BIN%\Infinity Battlescape.exe"

REM Documents is redirected to OneDrive on this machine.
set "IB_DOCS_CLIENT=%USERPROFILE%\OneDrive\Documents\I-Novae Studios\Infinity Battlescape"
if not exist "%IB_DOCS_CLIENT%" set "IB_DOCS_CLIENT=%USERPROFILE%\Documents\I-Novae Studios\Infinity Battlescape"
set "IB_DOCS_SERVER=%USERPROFILE%\OneDrive\Documents\I-Novae Studios\Infinity Battlescape Server"
if not exist "%IB_DOCS_SERVER%" set "IB_DOCS_SERVER=%USERPROFILE%\Documents\I-Novae Studios\Infinity Battlescape Server"

REM Match the working in-game local-mission launch (client-spawned server).
set "IB_MISSION_DEFAULT=%IB_DOCS_CLIENT%\Workshop\Empty.xml"
set "IB_SERVERCONFIG=LocalServerConfig.xml"

set "IB_HOST=127.0.0.1"
set "IB_PORT=7778"
set "IB_PORTRANGE=1"
set "IB_USERNAME=Pendrokar"
set "IB_PASSWORD=abcd1234"

set "IB_SERVER_PID_FILE=%~dp0server.pid"
set "IB_CLIENT_PID_FILE=%~dp0client.pid"
