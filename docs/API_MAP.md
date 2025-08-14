# 前端页面 / 路由 ↔ 后端接口映射

本表用于快速定位联调对象，变更后请及时更新。

## 认证
- 前端：Login/Register（/login, /register）
- 后端：POST /api/login, POST /api/register

## 看板（/application/kanban）
- GET /api/dashboard/overview?period=...
- GET /api/dashboard/top-customers
- GET /api/dashboard/materials?type=top|bottom
- GET /api/dashboard/urgent-orders
- GET /api/dashboard/financial-risk
- GET /api/dashboard/revenue-comparison
- GET /api/dashboard/all

## 销售订单管理（/application/manage-sales-orders）
- POST /api/so/search
- GET/POST /api/so/get/{so_id}

## 出库交货（/application/outbound-deliveries）
- POST /api/outbound/create-from-orders（创建交货；当前未锁定库存）
- POST /api/outbound/postGIsById（按 dlv_id 过账 GI，已扣减 On hand 并释放 Committed）
- POST /api/outbound/postGIs（按明细过账 GI，已扣减 On hand 并释放 Committed）

## 业务伙伴维护/关系
- 维护页：POST /api/bp/search, GET /api/bp/get/{customerId}, POST /api/bp/edit
- 关系页：/api/app/bp-* 系列（创建、展示、变更等，详见对应 Controller）

## 询价/报价/出库/开票/库存/物料凭证概览/入账
- 入口：对应 Controller 命名惯例（Inquiry, Quotation, OutboundDelivery, Billing, Stock, MaterialDocument, Finance, ValidateItems）
- 具体端点以各 Controller 文件定义为准（新增/变更时补充到此）

## 通用搜索
- 后端真实入口：POST /api/search
- 前端 SearchService 目前指向 /search/mock/*（如 /search/mock/simple），切真时改为后端真实路径

