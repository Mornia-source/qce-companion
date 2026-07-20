@echo off
chcp 65001 >nul
title QCE 前端 - 重新构建并部署
setlocal

set "ROOT=%~dp0"
set "FRONTEND=%ROOT%qq-chat-exporter-master\qce-v4-tool"
set "PLUGIN_WEBUI=%ROOT%NapCatQQ-main\packages\napcat-shell\dist\plugins\qq-chat-exporter\webui"

echo ============================================================
echo   重新构建 QCE 前端并部署到 NapCat 插件目录
echo   （改了 qce-v4-tool 里的代码，或者 git pull 官方更新后运行这个）
echo ============================================================
echo.

where pnpm >nul 2>&1
if errorlevel 1 (
    echo [信息] 未检测到 pnpm，尝试通过 corepack 启用...
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

echo [3/3] 部署静态文件到 NapCat 插件目录...
if exist "%PLUGIN_WEBUI%" rmdir /s /q "%PLUGIN_WEBUI%"
mkdir "%PLUGIN_WEBUI%"
xcopy "%FRONTEND%\out\*" "%PLUGIN_WEBUI%\" /e /i /y >nul

echo.
echo 完成。重启 NapCat（或重新运行 一键启动.bat）后刷新网页即可看到最新前端。
pause
exit /b 0

:error
echo.
echo [错误] 构建失败，请检查上面的报错信息。
pause
exit /b 1
