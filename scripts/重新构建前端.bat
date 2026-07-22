@echo off
title QCE Frontend - Rebuild and Deploy
setlocal

set "ROOT=%~dp0"
set "FRONTEND=%ROOT%qq-chat-exporter-master\qce-v4-tool"
set "PLUGIN_WEBUI=%ROOT%NapCatQQ-main\packages\napcat-shell\dist\plugins\qq-chat-exporter\webui"

echo ============================================================
echo   Rebuild QCE frontend and deploy to NapCat plugin folder
echo   (run this after editing qce-v4-tool, or after git pull)
echo ============================================================
echo.

where pnpm >nul 2>&1
if errorlevel 1 (
    echo [INFO] pnpm not found, enabling via corepack...
    call corepack enable
    call corepack prepare pnpm@latest --activate
)

cd /d "%FRONTEND%"
echo [1/3] pnpm install...
call pnpm install --frozen-lockfile
if errorlevel 1 goto :error

echo [2/3] pnpm build...
call pnpm build
if errorlevel 1 goto :error

echo [3/3] Deploying static files to NapCat plugin folder...
if exist "%PLUGIN_WEBUI%" rmdir /s /q "%PLUGIN_WEBUI%"
mkdir "%PLUGIN_WEBUI%"
xcopy "%FRONTEND%\out\*" "%PLUGIN_WEBUI%\" /e /i /y >nul

echo.
echo Done. Restart NapCat (or rerun the launch script) and refresh
echo the page to see the latest frontend.
pause
exit /b 0

:error
echo.
echo [ERROR] Build failed, check the messages above.
pause
exit /b 1
