# 整体架构概览

- 前端：Vue 3 + TypeScript + vue-router + Element Plus（目录：erp/site）
- 后端：Spring Boot 3.3.2（Java 22）+ MyBatis + MySQL + JWT（目录：backend/ERP）
- API 前缀：/api（CORS 全开）
- 前端服务地址：window.getAPIBaseUrl()（localStorage > env > 默认）
- 运行：前端本地直起；后端 docker 运行

系统边界与数据流：
1) 浏览器 -> 前端 SPA（/application 子路由承载各业务模块）
2) 前端 -> 后端 REST：认证、业务数据、看板统计
3) 后端 -> MySQL：MyBatis 注解 + XML 访问

关键模块：
- 认证与账号：/api/login, /api/register
- 业务伙伴（BP）、关系、SD 流程（询价→报价→销售订单→出库→发货→开票→收款）
- 看板 Dashboard：/api/dashboard/*

维护要点：
- 接口新增/变更需同步 API_MAP.md、前端调用代码与后端控制器
- 表结构变更需同步 DB_SCHEMA.md 与 SQL 脚本

