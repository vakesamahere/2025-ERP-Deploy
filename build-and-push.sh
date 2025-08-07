#!/bin/bash

# 构建和推送脚本
# 用于本地更新源代码后构建镜像并推送到 Docker Hub

set -e  # 遇到错误立即退出

# 配置变量
DOCKER_USERNAME="vakesamadocker"
BACKEND_IMAGE="erp-2025-backend"
FRONTEND_IMAGE="erp-2025-site"
TAG="latest"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查 Docker 是否运行
check_docker() {
    print_step "检查 Docker 是否运行..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker 未运行，请启动 Docker Desktop"
        exit 1
    fi
    print_message "Docker 运行正常"
}

# 拉取最新代码
pull_latest_code() {
    print_step "拉取最新代码..."
    if [ -d ".git" ]; then
        git pull origin main || git pull origin master || {
            print_warning "Git pull 失败，继续使用当前代码"
        }
        print_message "代码更新完成"
    else
        print_warning "当前目录不是 Git 仓库，跳过代码拉取"
    fi
}

# 检查是否已登录 Docker Hub
check_docker_login() {
    print_step "检查 Docker Hub 登录状态..."
    if ! docker info | grep -q "Username"; then
        print_warning "未登录 Docker Hub，请先登录"
        docker login
    fi
    print_message "Docker Hub 登录正常"
}

# 构建后端镜像
build_backend() {
    print_step "构建后端镜像..."
    docker build -f backend.Dockerfile -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG} .
    print_message "后端镜像构建完成"
}

# 构建前端镜像
build_frontend() {
    print_step "构建前端镜像..."
    docker build -f front.Dockerfile -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG} .
    print_message "前端镜像构建完成"
}

# 推送镜像到 Docker Hub
push_images() {
    print_step "推送镜像到 Docker Hub..."
    
    print_message "推送后端镜像..."
    docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG}
    
    print_message "推送前端镜像..."
    docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG}
    
    print_message "所有镜像推送完成"
}

# 清理本地镜像（可选）
cleanup_local() {
    read -p "是否清理本地构建的镜像？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "清理本地镜像..."
        docker rmi ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG} || true
        docker rmi ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG} || true
        print_message "本地镜像清理完成"
    fi
}

# 显示镜像信息
show_image_info() {
    print_step "镜像信息："
    echo "后端镜像: ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG}"
    echo "前端镜像: ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG}"
    echo ""
    echo "使用以下命令拉取镜像："
    echo "docker pull ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG}"
    echo "docker pull ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG}"
    echo ""
    echo "或使用生产环境 docker-compose："
    echo "docker-compose -f docker-compose.prod.yml up -d"
}

# 主函数
main() {
    print_message "开始构建和推送流程..."

    # 拉取最新代码
    pull_latest_code

    # 检查环境
    check_docker
    check_docker_login

    # 构建镜像
    build_backend
    build_frontend

    # 推送镜像
    push_images

    # 显示信息
    show_image_info

    # 可选清理
    cleanup_local

    print_message "构建和推送流程完成！"
}

# 帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -b, --backend  只构建和推送后端"
    echo "  -f, --frontend 只构建和推送前端"
    echo ""
    echo "示例:"
    echo "  $0              # 构建和推送所有镜像"
    echo "  $0 -b           # 只构建和推送后端"
    echo "  $0 -f           # 只构建和推送前端"
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--backend)
        pull_latest_code
        check_docker
        check_docker_login
        build_backend
        docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${TAG}
        print_message "后端镜像构建和推送完成！"
        ;;
    -f|--frontend)
        pull_latest_code
        check_docker
        check_docker_login
        build_frontend
        docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${TAG}
        print_message "前端镜像构建和推送完成！"
        ;;
    "")
        main
        ;;
    *)
        print_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
