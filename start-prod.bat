@echo off
setlocal

REM 生产环境快速启动脚本 (Windows 版本)
REM 用于拉取最新镜像并启动服务

set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

if "%1"=="--no-pull" goto :start_only
if "%1"=="--pull-only" goto :pull_only
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help
if "%1"=="" goto :main

echo 未知选项: %1
echo 使用 %0 --help 查看帮助
exit /b 1

:main
echo %GREEN%[INFO]%NC% 启动生产环境...

echo %BLUE%[STEP]%NC% 拉取最新镜像...
docker-compose -f docker-compose.prod.yml pull
if errorlevel 1 (
    echo 镜像拉取失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 镜像拉取完成

echo %BLUE%[STEP]%NC% 启动服务...
docker-compose -f docker-compose.prod.yml up -d
if errorlevel 1 (
    echo 服务启动失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 服务启动完成

goto :show_status

:start_only
echo %YELLOW%[WARNING]%NC% 跳过镜像拉取
echo %BLUE%[STEP]%NC% 启动服务...
docker-compose -f docker-compose.prod.yml up -d
if errorlevel 1 (
    echo 服务启动失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 服务启动完成
goto :show_status

:pull_only
echo %BLUE%[STEP]%NC% 拉取最新镜像...
docker-compose -f docker-compose.prod.yml pull
if errorlevel 1 (
    echo 镜像拉取失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 镜像拉取完成
goto :end

:show_status
echo.
echo %BLUE%[STEP]%NC% 服务状态：
docker-compose -f docker-compose.prod.yml ps

echo.
echo %GREEN%[INFO]%NC% 服务访问信息：
echo 前端: http://localhost:8083
echo 后端: http://localhost:3003
echo MySQL: localhost:3306
echo Redis: localhost:6379
echo.
echo 查看日志: docker-compose -f docker-compose.prod.yml logs -f
echo 停止服务: docker-compose -f docker-compose.prod.yml down
goto :end

:show_help
echo 用法: %0 [选项]
echo.
echo 选项:
echo   --no-pull    跳过镜像拉取，直接启动
echo   --pull-only  只拉取镜像，不启动
echo   -h, --help   显示帮助信息
goto :end

:end
pause
