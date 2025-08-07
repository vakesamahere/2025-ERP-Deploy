#!/bin/bash

# 生产环境快速启动脚本
# 用于拉取最新镜像并启动服务

set -e

# 配置变量
DOCKER_USERNAME="vakesamadocker"
BACKEND_IMAGE="erp-2025-backend"
FRONTEND_IMAGE="erp-2025-site"
VERSION_FILE="VERSION"

# 读取默认版本号
if [ -f "$VERSION_FILE" ]; then
    DEFAULT_VERSION=$(cat "$VERSION_FILE" | tr -d '\n')
else
    DEFAULT_VERSION="latest"
fi

# 使用指定版本或默认版本
VERSION=${1:-$DEFAULT_VERSION}

# 设置环境变量供 docker-compose 使用
export IMAGE_TAG=$VERSION

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 拉取指定版本的镜像
pull_images() {
    print_step "拉取镜像 (版本: ${VERSION})..."

    # 显示当前镜像信息
    print_message "当前本地镜像："
    docker images | grep -E "(${DOCKER_USERNAME}/erp-2025|REPOSITORY)" || echo "未找到相关镜像"

    # 使用 docker-compose 拉取指定版本的镜像
    print_message "使用 docker-compose 拉取镜像..."
    docker-compose -f docker-compose.prod.yml pull

    # 显示拉取后的镜像信息
    print_message "拉取后的镜像："
    docker images | grep -E "(${DOCKER_USERNAME}/erp-2025|REPOSITORY)" || echo "未找到相关镜像"

    print_message "镜像拉取完成"
}

# 清理旧镜像
cleanup_old_images() {
    print_step "清理旧的镜像版本..."

    # 清理悬空镜像（dangling images）
    dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        print_message "清理悬空镜像..."
        docker rmi $dangling_images 2>/dev/null || true
    fi

    # 清理旧版本的项目镜像（保留最新的）
    print_message "清理旧版本的项目镜像..."
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.CreatedAt}}" | \
    grep "vakesamadocker/erp-2025" | \
    tail -n +3 | \
    awk '{print $2}' | \
    xargs -r docker rmi 2>/dev/null || true

    print_message "镜像清理完成"
}

# 启动服务
start_services() {
    print_step "启动服务..."
    docker-compose -f docker-compose.prod.yml up -d
    print_message "服务启动完成"
}

# 显示服务状态
show_status() {
    print_step "服务状态："
    docker-compose -f docker-compose.prod.yml ps
}

# 显示访问信息
show_access_info() {
    echo ""
    print_message "服务访问信息："
    echo "前端: http://localhost:8083"
    echo "后端: http://localhost:3003"
    echo "MySQL: localhost:3306"
    echo "Redis: localhost:6379"
    echo ""
    echo "查看日志: docker-compose -f docker-compose.prod.yml logs -f"
    echo "停止服务: docker-compose -f docker-compose.prod.yml down"
}

# 主函数
main() {
    print_message "启动生产环境 (版本: ${VERSION})..."

    # 显示版本信息
    if [ "$VERSION" = "$DEFAULT_VERSION" ]; then
        print_message "使用默认版本: ${VERSION}"
    else
        print_message "使用指定版本: ${VERSION}"
    fi

    pull_images
    cleanup_old_images
    start_services
    show_status
    show_access_info
}

# 处理命令行参数
# 检查第一个参数是否是选项还是版本号
OPTION=""
if [[ "${1:-}" =~ ^-- ]] || [[ "${1:-}" == "-h" ]]; then
    # 第一个参数是选项
    OPTION="${1:-}"
    VERSION=$DEFAULT_VERSION
    export IMAGE_TAG=$VERSION
else
    # 第一个参数可能是版本号，第二个参数是选项
    if [ -n "${1:-}" ]; then
        VERSION="${1}"
        export IMAGE_TAG=$VERSION
    fi
    OPTION="${2:-}"
fi

case "$OPTION" in
    --no-pull)
        print_warning "跳过镜像拉取 (版本: ${VERSION})"
        start_services
        show_status
        show_access_info
        ;;
    --pull-only)
        pull_images
        cleanup_old_images
        ;;
    --cleanup-only)
        cleanup_old_images
        ;;
    --force-update)
        print_message "强制更新：停止服务 → 拉取镜像 → 清理旧镜像 → 重新启动 (版本: ${VERSION})"
        docker-compose -f docker-compose.prod.yml down
        pull_images
        cleanup_old_images
        start_services
        show_status
        show_access_info
        ;;
    -h|--help)
        echo "用法: $0 [版本号] [选项]"
        echo ""
        echo "版本号:"
        echo "  不指定        使用 VERSION 文件中的版本 (当前: ${DEFAULT_VERSION})"
        echo "  1.2.3         使用指定版本号"
        echo "  latest        使用最新版本"
        echo ""
        echo "选项:"
        echo "  --no-pull       跳过镜像拉取，直接启动"
        echo "  --pull-only     只拉取镜像和清理，不启动"
        echo "  --cleanup-only  只清理旧镜像"
        echo "  --force-update  强制更新：停止→拉取→清理→启动"
        echo "  -h, --help      显示帮助信息"
        echo ""
        echo "示例:"
        echo "  $0              # 使用默认版本 (${DEFAULT_VERSION})"
        echo "  $0 1.2.3        # 使用版本 1.2.3"
        echo "  $0 latest       # 使用最新版本"
        echo "  $0 1.2.3 --no-pull  # 使用版本 1.2.3，跳过拉取"
        echo ""
        echo "默认行为: 拉取指定版本镜像 → 清理旧镜像 → 启动服务"
        ;;
    "")
        main
        ;;
    *)
        echo "未知选项: $1"
        echo "使用 $0 --help 查看帮助"
        exit 1
        ;;
esac
