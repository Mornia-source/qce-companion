@echo off
title QQ Chat Exporter - Launch
setlocal

set "ROOT=%~dp0"
set "NAPCAT_DIST=%ROOT%NapCatQQ-main\packages\napcat-shell\dist"

if not exist "%NAPCAT_DIST%\launcher-user.bat" (
    echo [ERROR] Not found: %NAPCAT_DIST%\launcher-user.bat
    echo Please make sure NapCatQQ-main has been built as documented.
    pause
    exit /b 1
)

echo ============================================================
echo   QQ Chat Exporter - Launch
echo ============================================================
echo.
echo [1/2] Closing any running QQ.exe (NapCat needs to relaunch QQ
echo       in injected mode)...
taskkill /F /IM QQ.exe >nul 2>&1

echo [2/2] Starting NapCat (will auto-load the QQ Chat Exporter plugin)...
echo.
echo   A QR code will print to the console shortly - scan it with QQ
echo   on your phone to log in. After logging in, open:
echo     Chat export panel   http://127.0.0.1:40653/qce
echo     NapCat admin panel  http://127.0.0.1:6099/webui
echo.
echo   The QCE access token is saved at:
echo     %%USERPROFILE%%\.qq-chat-exporter\security.json
echo   Closing this window will also close QQ and require re-login,
echo   so please keep it open.
echo ============================================================
echo.

pushd "%NAPCAT_DIST%"
call "%NAPCAT_DIST%\launcher-user.bat"
popd
