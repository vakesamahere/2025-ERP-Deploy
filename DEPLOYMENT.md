# 🚀 Docker 部署指南

## 📋 文件清单

我已经为您创建了完整的 Docker 部署方案喵！

### 🐳 Docker 配置文件
- `docker-compose.prod.yml` - **生产环境配置**（从 Docker Hub 拉取镜像）
- `docker-compose.yml` - 本地开发配置（构建镜像）

### 🔨 构建和推送脚本
- `build-and-push.sh` - Linux/Mac 构建推送脚本
- `build-and-push.bat` - Windows 构建推送脚本

### ⚡ 快速启动脚本
- `start-prod.sh` - Linux/Mac 生产环境启动脚本
- `start-prod.bat` - Windows 生产环境启动脚本

## 🎯 使用场景

### 场景1: 本地开发和测试
```bash
# 构建并启动本地环境
docker-compose up -d --build
```

### 场景2: 代码更新后推送到 Docker Hub
```bash
# Linux/Mac
chmod +x build-and-push.sh
./build-and-push.sh

# Windows
build-and-push.bat
```

### 场景3: 生产环境部署（远程拉取）
```bash
# Linux/Mac
chmod +x start-prod.sh
./start-prod.sh

# Windows
start-prod.bat
```

## 🔄 完整工作流程

### 开发者工作流
1. **修改代码** 📝
2. **本地测试** 🧪
   ```bash
   docker-compose up -d --build
   ```
3. **推送镜像** 🚀
   ```bash
   ./build-and-push.sh
   ```

### 部署者工作流
1. **拉取最新镜像** ⬇️
2. **启动服务** ▶️
   ```bash
   ./start-prod.sh
   ```

## 🌟 核心优化特性

### 🚄 分层缓存优化
- 依赖层和代码层分离
- 只改代码时构建超快
- Maven 依赖缓存

### 🏗️ 多阶段构建
- 构建阶段：完整 Maven 环境
- 运行阶段：轻量级 JRE
- 镜像体积最小化

### 🔧 灵活的脚本选项
```bash
# 只构建后端
./build-and-push.sh -b

# 只构建前端  
./build-and-push.sh -f

# 跳过镜像拉取直接启动
./start-prod.sh --no-pull
```

## 📊 服务架构

```
┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │
│   (Port 8083)   │◄──►│   (Port 3003)   │
└─────────────────┘    └─────────────────┘
                              │
                              ▼
┌─────────────────┐    ┌─────────────────┐
│   MySQL         │    │   Redis         │
│   (Port 3306)   │    │   (Port 6379)   │
└─────────────────┘    └─────────────────┘
```

## 🎛️ 环境配置

### 生产环境变量
```yaml
SPRING_PROFILES_ACTIVE: prod
SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/webshop
SPRING_DATASOURCE_USERNAME: webshop
SPRING_DATASOURCE_PASSWORD: webshop123
SPRING_REDIS_HOST: redis
SPRING_REDIS_PORT: 6379
```

## 🔍 常用命令速查

### 查看状态
```bash
docker-compose -f docker-compose.prod.yml ps
```

### 查看日志
```bash
docker-compose -f docker-compose.prod.yml logs -f
```

### 停止服务
```bash
docker-compose -f docker-compose.prod.yml down
```

### 更新服务
```bash
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## 🎉 快速开始

1. **首次使用**：
   ```bash
   # 给脚本执行权限（Linux/Mac）
   chmod +x *.sh
   
   # 构建并推送镜像
   ./build-and-push.sh
   ```

2. **生产部署**：
   ```bash
   # 启动生产环境
   ./start-prod.sh
   ```

3. **访问服务**：
   - 前端：http://localhost:8083
   - 后端：http://localhost:3003

就是这么简单喵！🐱
