# 开发与运行/部署

## 前端（本地）
```bash
cd erp/site
npm install --force
npm run serve
```
- API 地址：window.getAPIBaseUrl()
  - 优先 localStorage:CUSTOM_API_BASE_URL
  - 其次 .env: VUE_APP_API_BASE_URL
  - 否则默认 http://124.70.192.112:3003

## 后端（Docker 运行）
- Spring Boot 端口：8080
- 配置：src/main/resources/application.properties（MySQL 等）

## 构建/部署
- 前端：front.Dockerfile（Node 构建 + Nginx 托管）
- 后端：Maven 打包 + Docker 部署（具体见团队实践）

## 常见问题
- 跨域：后端 @CrossOrigin("*") 已放开
- Token 注入：前端可在 axios/fetch 包装层统一注入 Authorization（如后端开启鉴权）

