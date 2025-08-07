@echo off
setlocal enabledelayedexpansion

REM 构建和推送脚本 (Windows 版本)
REM 用于本地更新源代码后构建镜像并推送到 Docker Hub

REM 配置变量
set DOCKER_USERNAME=vakesamadocker
set BACKEND_IMAGE=erp-2025-backend
set FRONTEND_IMAGE=erp-2025-site
set TAG=latest

REM 颜色代码 (Windows 10+ 支持)
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "BLUE=[94m"
set "NC=[0m"

echo %GREEN%[INFO]%NC% 开始构建和推送流程...

REM 拉取最新代码
echo %BLUE%[STEP]%NC% 拉取最新代码...
if exist ".git" (
    git pull origin main 2>nul || git pull origin master 2>nul || (
        echo %YELLOW%[WARNING]%NC% Git pull 失败，继续使用当前代码
    )
    echo %GREEN%[INFO]%NC% 代码更新完成
) else (
    echo %YELLOW%[WARNING]%NC% 当前目录不是 Git 仓库，跳过代码拉取
)

REM 检查 Docker 是否运行
echo %BLUE%[STEP]%NC% 检查 Docker 是否运行...
docker info >nul 2>&1
if errorlevel 1 (
    echo %RED%[ERROR]%NC% Docker 未运行，请启动 Docker Desktop
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% Docker 运行正常

REM 检查 Docker Hub 登录状态
echo %BLUE%[STEP]%NC% 检查 Docker Hub 登录状态...
docker info | findstr "Username" >nul
if errorlevel 1 (
    echo %YELLOW%[WARNING]%NC% 未登录 Docker Hub，请先登录
    docker login
    if errorlevel 1 (
        echo %RED%[ERROR]%NC% Docker Hub 登录失败
        pause
        exit /b 1
    )
)
echo %GREEN%[INFO]%NC% Docker Hub 登录正常

REM 处理命令行参数
if "%1"=="-h" goto :show_help
if "%1"=="--help" goto :show_help
if "%1"=="-b" goto :build_backend_only
if "%1"=="--backend" goto :build_backend_only
if "%1"=="-f" goto :build_frontend_only
if "%1"=="--frontend" goto :build_frontend_only
if "%1"=="" goto :build_all

echo %RED%[ERROR]%NC% 未知选项: %1
goto :show_help

:build_all
REM 构建后端镜像
echo %BLUE%[STEP]%NC% 构建后端镜像...
docker build -f backend.Dockerfile -t %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG% .
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 后端镜像构建失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 后端镜像构建完成

REM 构建前端镜像
echo %BLUE%[STEP]%NC% 构建前端镜像...
docker build -f front.Dockerfile -t %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG% .
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 前端镜像构建失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 前端镜像构建完成

REM 推送镜像到 Docker Hub
echo %BLUE%[STEP]%NC% 推送镜像到 Docker Hub...

echo %GREEN%[INFO]%NC% 推送后端镜像...
docker push %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 后端镜像推送失败
    pause
    exit /b 1
)

echo %GREEN%[INFO]%NC% 推送前端镜像...
docker push %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 前端镜像推送失败
    pause
    exit /b 1
)

echo %GREEN%[INFO]%NC% 所有镜像推送完成

goto :show_info

:build_backend_only
REM 拉取最新代码
echo %BLUE%[STEP]%NC% 拉取最新代码...
if exist ".git" (
    git pull origin main 2>nul || git pull origin master 2>nul || (
        echo %YELLOW%[WARNING]%NC% Git pull 失败，继续使用当前代码
    )
    echo %GREEN%[INFO]%NC% 代码更新完成
) else (
    echo %YELLOW%[WARNING]%NC% 当前目录不是 Git 仓库，跳过代码拉取
)

echo %BLUE%[STEP]%NC% 构建后端镜像...
docker build -f backend.Dockerfile -t %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG% .
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 后端镜像构建失败
    pause
    exit /b 1
)
docker push %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 后端镜像推送失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 后端镜像构建和推送完成！
goto :end

:build_frontend_only
REM 拉取最新代码
echo %BLUE%[STEP]%NC% 拉取最新代码...
if exist ".git" (
    git pull origin main 2>nul || git pull origin master 2>nul || (
        echo %YELLOW%[WARNING]%NC% Git pull 失败，继续使用当前代码
    )
    echo %GREEN%[INFO]%NC% 代码更新完成
) else (
    echo %YELLOW%[WARNING]%NC% 当前目录不是 Git 仓库，跳过代码拉取
)

echo %BLUE%[STEP]%NC% 构建前端镜像...
docker build -f front.Dockerfile -t %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG% .
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 前端镜像构建失败
    pause
    exit /b 1
)
docker push %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG%
if errorlevel 1 (
    echo %RED%[ERROR]%NC% 前端镜像推送失败
    pause
    exit /b 1
)
echo %GREEN%[INFO]%NC% 前端镜像构建和推送完成！
goto :end

:show_info
echo.
echo %BLUE%[STEP]%NC% 镜像信息：
echo 后端镜像: %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG%
echo 前端镜像: %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG%
echo.
echo 使用以下命令拉取镜像：
echo docker pull %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG%
echo docker pull %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG%
echo.
echo 或使用生产环境 docker-compose：
echo docker-compose -f docker-compose.prod.yml up -d
echo.

REM 询问是否清理本地镜像
set /p cleanup="是否清理本地构建的镜像？(y/N): "
if /i "%cleanup%"=="y" (
    echo %BLUE%[STEP]%NC% 清理本地镜像...
    docker rmi %DOCKER_USERNAME%/%BACKEND_IMAGE%:%TAG% 2>nul
    docker rmi %DOCKER_USERNAME%/%FRONTEND_IMAGE%:%TAG% 2>nul
    echo %GREEN%[INFO]%NC% 本地镜像清理完成
)

echo %GREEN%[INFO]%NC% 构建和推送流程完成！
goto :end

:show_help
echo 用法: %0 [选项]
echo.
echo 选项:
echo   -h, --help     显示帮助信息
echo   -b, --backend  只构建和推送后端
echo   -f, --frontend 只构建和推送前端
echo.
echo 示例:
echo   %0              # 构建和推送所有镜像
echo   %0 -b           # 只构建和推送后端
echo   %0 -f           # 只构建和推送前端
goto :end

:end
pause
