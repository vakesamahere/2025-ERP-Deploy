# 后端说明（backend/ERP）

## 技术栈
- Spring Boot 3.3.2（Java 22）、MyBatis、MySQL、JWT、Lombok

## 入口与配置
- 入口：webserver.WebshopApplication（@MapperScan("webserver.mapper")）
- 配置：src/main/resources/application.properties（端口 8080、MySQL、MyBatis、JWT）

## 分层结构
- controller（REST）：AuthController、BusinessPartnerController、SalesOrderController、QuotationController、InquiryController、OutboundDeliveryController、BillingController、StockController、MaterialDocumentController、FinanceController、ValidateItemsController、DashboardController 等
- service / service.impl：业务逻辑与组合
- mapper（接口 + XML）：部分注解查询（如 DashboardMapper），多数复杂查询在 XML（如 SalesOrderMapper.xml）
- common/util：统一响应 Response、JwtUtil 等

## 典型接口示例
- 认证：POST /api/register、POST /api/login
- 销售订单：/api/so/search，/api/so/get/{so_id}
- 看板：/api/dashboard/overview, /top-customers, /materials, /urgent-orders, /financial-risk, /revenue-comparison, /all

## 出库交货与库存联动
- 创建交货（create-from-orders）：仅生成交货与明细记录；库存未锁定
- 过账 GI（postGIsById/postGIs）：
  - 在 Service 中按交货明细逐行调用 StockMapper.issueAndRelease，执行：
    - qty_on_hand -= pickingQuantity
    - qty_committed = max(qty_committed - pickingQuantity, 0)
  - 如需“承诺库存”在创建交货时生效，可启用 stockMapper.reserveStock（当前代码留有注释位）

## 维护要点
- 新增端点需同步 API_MAP.md 与前端调用
- Mapper 变动需更新对应 XML 与单测

