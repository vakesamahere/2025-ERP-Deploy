# 前端说明（erp/site）

## 技术栈
- Vue 3 + TypeScript + vue-router 4 + Element Plus
- 构建：@vue/cli-service（serve/build），依赖中包含 Vite

## 入口与全局配置
- src/main.ts 注册路由与全局 API_BASE_URL：
  - 读取 localStorage:CUSTOM_API_BASE_URL → env:VUE_APP_API_BASE_URL → 默认 http://124.70.192.112:3003

## 路由设计
- 父路由 /application 承载业务子路由（BP维护/关系、销售订单、询价、出库、开票、库存、物料凭证概览、看板、入账等）
- 代码：src/router/index.ts

## API 调用规范
- 使用 window.getAPIBaseUrl() 拼接后端地址
- axios：认证（/api/register, /api/login）
- fetch：Dashboard 与通用搜索等

## 复杂表单与变量树
- utils/VarTree.ts 提供 VarNode/VarTree，支持：
  - 动态结构（dict/list/leaf）、校验器、搜索方法 SearchMethod(serviceUrl) 与回填

## 状态管理
- 未使用 pinia/vuex，组件内状态 + VarTree 工具

## 常见联调要点
- 注意 Authorization 头（当前登录后 token 未全局注入，后续可在拦截器或 fetch 包装统一注入）
- SearchService 默认指向 /search/mock/*，对接真实后端需改为 /api/search 或对应路径

