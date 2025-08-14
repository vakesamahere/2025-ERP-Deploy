# 数据库结构与关系

SQL 文件：backend/ERP/src/main/resources/sql

## 关键表（节选）
- 参考：erp_company_code, erp_language, erp_currency, erp_customer_title, erp_title, erp_sort_key, erp_payment_terms, erp_sales_org, erp_distribution_channel, erp_division, erp_sales_district, erp_price_group, erp_customer_group, erp_deliver_priority, erp_shipping_condition, erp_acct, erp_reconciliation_account, erp_plant_name, erp_storage_location, erp_order_status, erp_management, erp_department, erp_function
- 主数据：erp_customer, erp_contact, erp_relation（BP 关系）, erp_material, erp_stock
- SD 流程：erp_inquiry(+items), erp_quotation(+items), erp_sales_order_hdr(+erp_sales_item), erp_outbound_delivery(+items), erp_good_issue, erp_billing_hdr(+items), erp_payment, erp_pricing_element

## 典型链路
询价 → 报价 → 销售订单 → 出库交货 → 发货（GI） → 开票 → 收款

## 示例（节选）
- 销售订单头：so_id 主键，customer_no 外键 -> erp_customer，payment_terms -> erp_payment_terms
- 定价元素 erp_pricing_element 关联 (so_id,item_no) → erp_sales_item

## 维护要点
- 表结构调整需同步 SQL 脚本与本文件
- 外键变更会影响多表联查与 Mapper SQL（XML/注解）

