# ECP 对接 user_auth 标准用户系统改造

> 目标：ECP 接入 Kong 网关统一认证。前端请求经 Kong 用 user_auth 的 token 鉴权后转发，ECP 后端识别 user_auth token 并映射到本地用户。**现有 BFBase 登录保留，双轨并存。**

## 方案选型

**user_auth 认证 + emp_no 映射 QMS User（方案 A）**。

放弃完全替换 QMS 用户体系的原因：业务表（外销单/托运/文件/日志）中已存满 QMS User ID，控制器层有 65+ 处 `PortalDomain.GetUsers()` 批量查询调用，且 user_auth 缺少按 ID 批量查用户、按角色/供应商查用户的 API。完全切换需迁移全部业务数据 + 重写所有用户查询，代价远大于收益。

方案 A 的本质：**user_auth 只做认证（token 校验 + 身份识别），QMS User 表继续做业务数据锚点**，通过员工工号（user_auth `emp_no` ↔ QMS `EmployeeNumber`）桥接。

## 认证流程

```
请求（Authorization: Bearer <user_auth token>）
  │
  ├─ JwtFilter.TryUserAuthAsync()
  │   ├─ 调 user_auth GET /auth/current（带 Bearer，3s 超时）
  │   ├─ 解析 data.emp_no + data.role[].key
  │   ├─ 按 EmployeeNumber == emp_no 查 QMS User
  │   ├─ 找到 → 设置 8 个 claims + Items["LoginedUser"] → 放行
  │   └─ 任何失败 → 返回 false
  │
  └─ 回退 BFBase JWT（JwtEncrypt.AutoRefreshToken，现有逻辑）
      ├─ 成功 → 放行
      └─ 失败 → context.Fail()
```

user_auth `/auth/current` 响应结构：`Response(data=...)` 包装，data 含 `emp_no`（员工编号）、`role[]`（数组，元素含 `role_id`、`key`、`name`）、`name`、`loginid`、`main_department` 等。

## 代码改动（3 个文件）

### 1. appsettings.json — 新增配置

```json
"ExternalServices": {
  "UserAuth": {
    "BaseUrl": "http://192.168.111.243:31016/api/user_auth"
  }
}
```

### 2. Program.cs — 注册 HttpClient（AddJwt 之后）

```csharp
builder.Services.AddHttpClient("UserAuthApi", c =>
{
    c.BaseAddress = new Uri(builder.Configuration["ExternalServices:UserAuth:BaseUrl"]);
    c.Timeout = TimeSpan.FromSeconds(3);
});
```

无需新增 NuGet 包（IHttpClientFactory 内置于 .NET 6 Web SDK）。

### 3. JwtFilter.cs — 核心改造

- 构造函数新增注入 `IHttpClientFactory`，启用原已注入但未使用的 `SugarRepository<User>`
- `HandleAsync` 先走 `TryUserAuthAsync`，失败回退现有 BFBase JWT 逻辑
- `TryUserAuthAsync`：取 Bearer token → 调 `/auth/current` → 解析 emp_no + role keys → 按 EmployeeNumber 查 User → 设 claims → 异常一律 catch 返回 false

#### Claims 设置（兼容现有全链路）

| Claim | 来源 | 依赖方 |
|-------|------|--------|
| `UserId` | QMS User.Id | `Permeate.LoginedUser`（40+ 处业务归属）|
| `Username` | QMS User.Username | 门户参数 |
| `RoleId` | QMS User.RoleId | PortalController 参数范围过滤 |
| `RoleIds` | user_auth role[].role_id 逗号拼接 | ChatHub SignalR 角色分组 |
| `DepartmentId` | QMS User.DepartmentId | 销售管理部门视角 |
| `TargetId` | QMS User.TargetId | 货代/报关行供应商隔离（ForwarderProviderId/CustomsBrokerProviderId）|
| `TargetModule` | QMS User.TargetModule | 供应商角色判断 |
| `Domains` | role key 映射（见下表）逗号拼接 | 控制器管理/销售视角判断 |

设置 `httpContext.User = new ClaimsPrincipal(new ClaimsIdentity(claims, "user_auth"))` 及 `Items["LoginedUser"]` 后，`Permeate.LoginedUser`、`PortalDomain.LoginedUser`、控制器 Domains 判断、ChatHub 分组全部无需改动。

#### 角色 → Domains 映射（代码硬编码）

| user_auth role key | Domains claim 值 |
|--------------------|------------------|
| `ecp_salesman` | `ForeignSale.Domains.SalesmanDomain` |
| `ecp_sales_manager` | `ForeignSale.Domains.SalesManagerDomain,ForeignSale.Domains.SalesmanDomain` |
| `ecp_forwarder` | `ForeignSale.Domains.ForwarderDomain` |
| `ecp_customs_broker` | `ForeignSale.Domains.CustomsBrokerDomain` |
| `ecp_sales_support` | `ForeignSale.Domains.SalesSupportDomain` |

- 多角色用户：Domains 取所有角色映射的并集去重
- `ecp_sales_manager` 必须映射两个 Domain：ShippingOrder/Customer/ForeignSale 三个控制器要求 `_domains.Length > 1` 才走管理视角

## 前提条件

1. QMS_Biz `dbo.[user]` 表中所有 ECP 用户有 `employee_number` 且与 user_auth `emp_no` 一致
2. user_auth 预设上表 5 种 `ecp_` 前缀角色并分配给相应用户
3. Kong 转发时保留 `Authorization` 头

## 明确不改的

- `PortalController.Login()` — BFBase 登录保留，双轨并存
- `Permeate.LoginedUser`（Domains/Extensions.cs）— 从 UserId claim 查 User，自动兼容
- ChatHub、全部 Domain/Controller — claims 兼容，零改动

## 验证

1. `dotnet build ForeignSale.sln` 编译通过
2. 携带 user_auth token 请求任意接口 → 正常返回业务数据
3. 携带 BFBase JWT 请求 → 回退逻辑正常（双轨验证）
4. 无 token / 无效 token → 401

## 后续演进（可选）

若要逐步摆脱 QMS 用户表依赖：先在 user_auth 补齐批量查用户 API（按 ID 列表 / 按角色 key / 按供应商 target_id），再分批替换 `PortalDomain.GetUsers()` 调用，最后迁移业务表 User ID。属渐进式重构，本次不做。
