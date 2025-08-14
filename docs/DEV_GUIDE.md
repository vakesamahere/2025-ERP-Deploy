# AI 辅助开发指南（后端接口改动）

目标：让人机协作顺畅，AI 与开发者对后端接口的修改有一致的方法论与落地步骤。

## 1. 后端分层结构速览
- Controller（webserver.controller.*）：
  - 暴露 REST 接口（@RestController / @RequestMapping / @GetMapping / @PostMapping）
  - 负责参数接收、简单校验、调用 Service 层
  - 返回统一响应对象 webserver.common.Response
- Service 接口（webserver.service.*）：
  - 定义业务能力（接口），隔离 Controller 与数据访问
- Service 实现（webserver.service.impl.*）：
  - 组织业务流程、组合多个 Mapper 调用、封装事务与校验
- Mapper 接口（webserver.mapper.*）：
  - MyBatis 映射接口，可用 @Select/@Insert 等注解，或与 XML 文件配合
- Mapper XML（src/main/resources/mapper/*.xml）：
  - 复杂 SQL 与动态 SQL 建议放在 XML 中，namespace 指向对应 Mapper 接口

示意调用链：Controller → Service → Mapper(接口) ↔ Mapper XML → MySQL

## 2. 新增/修改接口的一般步骤
1) 设计接口
   - 路由与方法：/api/module/action（GET/POST/PUT/DELETE）
   - 请求/响应模型：在 webserver.pojo 下新增/复用 DTO/Request/Response 类
   - 响应统一使用 Response<T>
2) Controller
   - 在对应 *Controller.java 中新增方法
   - 使用 @RequestMapping/@GetMapping/@PostMapping 标注路径
   - 参数绑定（@RequestBody、@PathVariable、@RequestParam）
   - 调用 Service 并返回 Response
3) Service 与 Impl
   - 在 webserver.service 中新增方法签名
   - 在 webserver.service.impl 中实现，编排业务逻辑，处理校验/异常，调用 Mapper
4) Mapper 与 XML
   - 在 webserver.mapper 中新增方法
   - 在 resources/mapper/*.xml 中补充对应 <select>/<insert>/<update>/<delete>
   - namespace 必须与 Mapper 接口的全限定名一致
   - id 与 Mapper 方法名一致；入参命名与 @Param 映射一致
5) 配置检查
   - 确认 application.properties 的 mybatis.mapper-locations=classpath:/mapper/*.xml
   - 若新增 XML，文件名无强制要求，但需位于该路径被扫描到
6) 联调与测试
   - 本地或 docker 环境启动后端；使用前端或 Postman 进行调用
   - 若涉及数据库结构变更，更新 SQL 并跑入库脚本，更新 docs/DB_SCHEMA.md
7) 文档同步
   - 更新 docs/API_MAP.md（页面/路由 ↔ 接口映射）
   - 更新 docs/BACKEND.md（列出控制器与关键端点）
   - 如有架构层面的调整，更新 docs/ARCHITECTURE.md

## 3. 代码骨架参考

### 3.1 Controller 例（片段）
```java
@RestController
@RequestMapping("/api/so")
@CrossOrigin(origins = "*")
public class SalesOrderController {
  @Autowired private SalesOrderService salesOrderService;

  @PostMapping("/search")
  public Response<?> search(@RequestBody SalesOrderSearchRequest req){
    return salesOrderService.searchSalesOrders(req);
  }
}
```

### 3.2 Service 接口与实现（片段）
```java
public interface SalesOrderService {
  Response<?> searchSalesOrders(SalesOrderSearchRequest req);
}

@Service
public class SalesOrderServiceImpl implements SalesOrderService {
  @Autowired private SalesOrderMapper salesOrderMapper;
  public Response<?> searchSalesOrders(SalesOrderSearchRequest req){
    var list = salesOrderMapper.searchSalesOrders(req.getSoId(), req.getStatus(), ...);
    return Response.success(list);
  }
}
```

### 3.3 Mapper 与 XML（片段）
```java
@Mapper
public interface SalesOrderMapper {
  List<Map<String,Object>> searchSalesOrders(@Param("soId") String soId,
     @Param("status") String status,
     @Param("customerNo") String customerNo,
     @Param("customerReference") String customerReference);
}
```

```xml
<!-- resources/mapper/SalesOrderMapper.xml -->
<mapper namespace="webserver.mapper.SalesOrderMapper">
  <select id="searchSalesOrders" resultType="map">
    SELECT ... FROM erp_sales_order_hdr so ...
    <where>
      <if test="soId != null and soId != ''">AND so.so_id = #{soId}</if>
      <if test="status != null and status != ''">AND so.status = #{status}</if>
      ...
    </where>
    ORDER BY so.so_id DESC
  </select>
</mapper>
```

## 4. 修改接口的注意事项
- 向后兼容：如前端已使用 GET /api/so/get/{id}，新增 POST 版本时可并存（项目已有范例）
- DTO 变更：新增字段尽量后向兼容（加默认值）；删除/改名需同步前端与文档
- SQL 变更：谨慎改动 SELECT 字段别名（前端以别名绑定 UI），同时更新 XML 与 Mapper 方法返回类型

## 5. 数据库变更流程
1) 修改/新增 SQL（resources/sql 下）
2) 同步 DB_SCHEMA.md 描述与外键关系
3) 本地或 docker 环境执行脚本，确保外键完整性
4) 回归涉及的 Mapper SQL 与接口

## 6. 联调建议（AI 侧执行清单）
- 自动定位：根据路由/接口关键词在 controller/service/mapper/xml 中交叉检索
- 严谨修改：优先 XML，避免在多个位置复制 SQL；注解 SQL 与 XML 同名方法避免冲突
- 验证：
  - 编译：mvn -q -DskipTests package
  - 端测：调用新增/改动接口（MockMvc 或 Postman）
  - 前端：查 API_MAP.md 定位页面联调
- 文档：修改完成后更新 API_MAP.md/BACKEND.md/DB_SCHEMA.md

## 7. 常见问题与速解
- 404：检查 @RequestMapping 前缀与方法级路径是否正确拼接
- 400/415：检查 @RequestBody DTO 定义与 Content-Type
- 500：查看日志堆栈；常见为 Mapper 参数命名与 XML #{} 不一致
- SQL 不生效：确认 mapper-locations 配置、namespace、id 与方法一致

—— 人机协作愉快！

