@echo off
chcp 65001 >nul
title QQ 聊天记录导出 - 一键启动
setlocal

set "ROOT=%~dp0"
set "NAPCAT_DIST=%ROOT%NapCatQQ-main\packages\napcat-shell\dist"

if not exist "%NAPCAT_DIST%\launcher-user.bat" (
    echo [错误] 没找到 %NAPCAT_DIST%\launcher-user.bat
    echo 请确认 NapCatQQ-main 已经按说明构建过。
    pause
    exit /b 1
)

echo ============================================================
echo   QQ 聊天记录导出 - 一键启动
echo ============================================================
echo.
echo [1/2] 关闭正在运行的 QQ（NapCat 需要以注入模式重新启动 QQ）...
taskkill /F /IM QQ.exe >nul 2>&1

echo [2/2] 启动 NapCat（会自动加载"QQ 聊天记录导出"插件）...
echo.
echo   稍后控制台会打印一个二维码，用手机 QQ 扫码登录。
echo   登录成功后可以打开：
echo     聊天记录导出面板   http://127.0.0.1:40653/qce
echo     NapCat 管理面板     http://127.0.0.1:6099/webui
echo.
echo   QCE 的访问令牌保存在：%%USERPROFILE%%\.qq-chat-exporter\security.json
echo   关闭这个窗口会导致 QQ 一并退出、需要重新登录，请保持窗口开启。
echo ============================================================
echo.

cd /d "%NAPCAT_DIST%"
call launcher-user.bat
