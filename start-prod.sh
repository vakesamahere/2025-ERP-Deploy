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
    print_step "拉取最新镜像..."
    docker-compose -f docker-compose.prod.yml pull
    print_message "镜像拉取完成"
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
        ;;
    -h|--help)
        echo "用法: $0 [选项]"
        echo ""
        echo "选项:"
        echo "  --no-pull    跳过镜像拉取，直接启动"
        echo "  --pull-only  只拉取镜像，不启动"
        echo "  -h, --help   显示帮助信息"
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
