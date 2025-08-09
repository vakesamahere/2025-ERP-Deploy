#!/bin/bash

# 构建和推送脚本
# 用于本地更新源代码后构建镜像并推送到 Docker Hub

set -e  # 遇到错误立即退出

# 配置变量
DOCKER_USERNAME="vakesamadocker"
BACKEND_IMAGE="erp-2025-backend"
FRONTEND_IMAGE="erp-2025-site"
VERSION_FILE="VERSION"

# 读取当前版本号
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
else
    CURRENT_VERSION="1.0.0"
    echo "$CURRENT_VERSION" > "$VERSION_FILE"
fi

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

# 版本管理函数
increment_version() {
    local version=$1
    local type=${2:-patch}  # patch, minor, major

    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}

    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            print_error "无效的版本类型: $type (支持: major, minor, patch)"
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# 显示版本信息
show_version_info() {
    print_step "版本信息："
    echo "当前版本: $CURRENT_VERSION"
    echo "新版本: $NEW_VERSION"
    echo ""
}

# 更新版本号
update_version() {
    local version_type=${1:-patch}
    NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$version_type")

    print_step "版本更新："
    echo "从 $CURRENT_VERSION → $NEW_VERSION ($version_type)"

    # 更新版本文件
    echo "$NEW_VERSION" > "$VERSION_FILE"
    print_message "版本文件已更新"
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

# 获取当前分支名
get_current_branch() {
    local dir=$1
    if [ -d "$dir" ]; then
        cd "$dir"
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        cd ..
        echo "$branch"
    else
        echo "main"  # 默认分支
    fi
}

# 拉取前后端仓库代码
pull_latest_code() {
    print_step "拉取前后端仓库代码..."

    # 拉取前端代码
    if [ -d "erp" ]; then
        print_message "更新前端代码..."
        cd erp
        local frontend_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "test/fake-main")
        print_message "前端当前分支: $frontend_branch"
        git pull origin "$frontend_branch" || {
            print_warning "前端代码 pull 失败，继续使用当前代码"
        }
        cd ..
    else
        print_message "克隆前端仓库..."
        git clone -b test/fake-main git@github.com:pezy-yx/ERP-SD-simplified.git erp || {
            print_error "前端仓库克隆失败"
            exit 1
        }
    fi

    # 拉取后端代码
    if [ -d "backend" ]; then
        print_message "更新后端代码..."
        cd backend
        local backend_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
        print_message "后端当前分支: $backend_branch"
        git pull origin "$backend_branch" || {
            print_warning "后端代码 pull 失败，继续使用当前代码"
        }
        cd ..
    else
        print_message "克隆后端仓库..."
        git clone -b main git@github.com:yyq856/ERP.git backend || {
            print_error "后端仓库克隆失败"
            exit 1
        }
    fi

    print_message "前后端代码更新完成"
}

# 显示当前分支信息
show_branch_info() {
    print_step "当前分支信息："

    if [ -d "erp" ]; then
        local frontend_branch=$(get_current_branch "erp")
        echo "前端分支: $frontend_branch"
    else
        echo "前端分支: 未克隆 (将使用 test/fake-main)"
    fi

    if [ -d "backend" ]; then
        local backend_branch=$(get_current_branch "backend")
        echo "后端分支: $backend_branch"
    else
        echo "后端分支: 未克隆 (将使用 main)"
    fi
    echo ""
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
    docker build -f backend.Dockerfile \
        -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${NEW_VERSION} \
        -t ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest .
    print_message "后端镜像构建完成 (${NEW_VERSION})"
}

# 构建前端镜像
build_frontend() {
    print_step "构建前端镜像..."
    docker build -f front.Dockerfile \
        -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${NEW_VERSION} \
        -t ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest .
    print_message "前端镜像构建完成 (${NEW_VERSION})"
}

# 推送镜像到 Docker Hub
push_images() {
    print_step "推送镜像到 Docker Hub..."

    print_message "推送后端镜像 (版本: ${NEW_VERSION})..."
    docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${NEW_VERSION}
    docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest

    print_message "推送前端镜像 (版本: ${NEW_VERSION})..."
    docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${NEW_VERSION}
    docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest

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
    echo "版本: ${NEW_VERSION}"
    echo "后端镜像: ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${NEW_VERSION}"
    echo "前端镜像: ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${NEW_VERSION}"
    echo ""
    echo "使用以下命令拉取特定版本："
    echo "docker pull ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${NEW_VERSION}"
    echo "docker pull ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${NEW_VERSION}"
    echo ""
    echo "或拉取最新版本："
    echo "docker pull ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest"
    echo "docker pull ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest"
    echo ""
    echo "生产环境部署："
    echo "1. 更新 docker-compose.prod.yml 中的版本号为 ${NEW_VERSION}"
    echo "2. 运行: docker-compose -f docker-compose.prod.yml up -d"
}

# 主函数
main() {
    local version_type=${1:-patch}

    print_message "开始构建和推送流程..."

    # 显示当前分支信息
    show_branch_info

    # 拉取最新代码
    pull_latest_code

    # 更新版本号
    update_version "$version_type"
    show_version_info

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
    echo "用法: $0 [选项] [版本类型]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -b, --backend  只构建和推送后端"
    echo "  -f, --frontend 只构建和推送前端"
    echo "  --major        主版本更新 (x.0.0)"
    echo "  --minor        次版本更新 (x.y.0)"
    echo "  --patch        补丁版本更新 (x.y.z) [默认]"
    echo ""
    echo "当前版本: $CURRENT_VERSION"
    echo ""
    echo "示例:"
    echo "  $0              # 构建所有镜像 (patch 版本)"
    echo "  $0 --minor      # 构建所有镜像 (minor 版本)"
    echo "  $0 --major      # 构建所有镜像 (major 版本)"
    echo "  $0 -b           # 只构建后端 (patch 版本)"
    echo "  $0 -f           # 只构建前端 (patch 版本)"
}

# 处理命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -b|--backend)
        show_branch_info
        pull_latest_code
        update_version "patch"
        show_version_info
        check_docker
        check_docker_login
        build_backend
        docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:${NEW_VERSION}
        docker push ${DOCKER_USERNAME}/${BACKEND_IMAGE}:latest
        print_message "后端镜像构建和推送完成！(版本: ${NEW_VERSION})"
        ;;
    -f|--frontend)
        show_branch_info
        pull_latest_code
        update_version "patch"
        show_version_info
        check_docker
        check_docker_login
        build_frontend
        docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:${NEW_VERSION}
        docker push ${DOCKER_USERNAME}/${FRONTEND_IMAGE}:latest
        print_message "前端镜像构建和推送完成！(版本: ${NEW_VERSION})"
        ;;
    --major)
        main "major"
        ;;
    --minor)
        main "minor"
        ;;
    --patch)
        main "patch"
        ;;
    "")
        main "patch"
        ;;
    *)
        print_error "未知选项: $1"
        show_help
        exit 1
        ;;
esac
