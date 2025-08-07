#!/bin/bash

# 生产环境快速启动脚本
# 用于拉取最新镜像并启动服务

set -e

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

# 拉取最新镜像
pull_images() {
    print_step "强制拉取最新镜像..."

    # 显示当前镜像信息
    print_message "当前本地镜像："
    docker images | grep -E "(vakesamadocker/erp-2025|REPOSITORY)" || echo "未找到相关镜像"

    # 强制拉取最新镜像（即使本地已存在）
    docker-compose -f docker-compose.prod.yml pull --ignore-pull-failures

    # 显示拉取后的镜像信息
    print_message "拉取后的镜像："
    docker images | grep -E "(vakesamadocker/erp-2025|REPOSITORY)" || echo "未找到相关镜像"

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
    print_message "启动生产环境..."
    pull_images
    cleanup_old_images
    start_services
    show_status
    show_access_info
}

# 处理命令行参数
case "${1:-}" in
    --no-pull)
        print_warning "跳过镜像拉取"
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
        print_message "强制更新：停止服务 → 拉取镜像 → 清理旧镜像 → 重新启动"
        docker-compose -f docker-compose.prod.yml down
        pull_images
        cleanup_old_images
        start_services
        show_status
        show_access_info
        ;;
    -h|--help)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --no-pull       跳过镜像拉取，直接启动"
        echo "  --pull-only     只拉取镜像和清理，不启动"
        echo "  --cleanup-only  只清理旧镜像"
        echo "  --force-update  强制更新：停止→拉取→清理→启动"
        echo "  -h, --help      显示帮助信息"
        echo ""
        echo "默认行为: 拉取最新镜像 → 清理旧镜像 → 启动服务"
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
