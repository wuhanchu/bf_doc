# API 网关

基于 Kong 的双层 API 网关体系。大部分服务都通过 Kong 代理对外提供，在网关层实现统一的流量控制、身份认证和监控。

## 双层网关架构

外网与内网两层 Kong 网关分离部署：

| 层 | 职责 |
|------|------|
| 外网网关 | 外部流量统一接入、IP 黑白名单控制、HTTPS 卸载 |
| 内网网关 | 内部服务调用、负载均衡 / 统一路由、认证鉴权、日志监控 |

**设计要点：**

- 所有外部请求统一经由外网网关转发，通过 IP 黑白名单杜绝非法连接
- 网关前置 IPS 硬件防御设备，拦截 SQL 注入、DDoS 等外部攻击
- 接口调用必须通过认证中心授权，防止内部系统单点被攻破后全线"裸奔"
- 底层资源（数据库/虚拟机）仅对受信任的容器集群 IP 开放

## 流量链路

```
外部访问：外部客户端 → 外网网关 → 内网网关 → 前端服务 / 后台服务
内部访问：内部客户端 → 内网网关 → 负载均衡/统一路由 → 业务系统 / 自研服务
```

## 统一代理

服务统一通过 Kong 的 **Service + Route** 模型接入：

- **Service** — 定义上游服务地址（后端真实地址）
- **Route** — 定义匹配规则（host / path / port），流量按规则转发到 Service

**要点：**

- 对外 URL 统一带 `api` 前缀（如 `api.xxx.com/api/v1/users`），前缀由网关配置剥离，服务实现无需处理（见 [API 规范](../02_开发规范/02_API规范.md)）
- 反向代理场景需设置 `preserve_host=true`，否则回调 URL 会丢失端口号（如 OnlyOffice）
- WebSocket 升级需在路由上显式支持（如 OnlyOffice 文档协作通道）

**配置示例（Admin API）：**

```bash
# 创建 Service
curl -i -X POST http://localhost:31017/services \
  --data name=onlyoffice \
  --data url='http://192.168.31.226:31581'

# 创建 Route
curl -i -X POST http://localhost:31017/services/onlyoffice/routes \
  --data name=onlyoffice \
  --data 'hosts[]=asus.uglyxu.cn:31022' \
  --data 'paths[]=/' \
  --data preserve_host=true
```

## 控制与监控

### 认证控制（auth-check 插件）

自研 Kong `auth-check` 插件，配合 [权限服务](03_权限服务.md) 在网关层完成统一鉴权：

```
客户端请求 → Kong（auth-check 插件）→ 调用 user_auth 鉴权 → 缓存结果 → 转发到后端服务
```

- Token 来源优先级：URL 参数（ticket/token）→ Header（Authorization）→ Cookie
- token 来自 URL 或 Cookie 时，网关自动注入 `Authorization` header
- 鉴权结果按 `cache_ttl` 缓存，减少对权限服务的调用

### 访问控制

- `skip_paths` — 跳过校验的路径前缀（开放接口）
- `skip_ips` — 跳过校验的 IP 前缀（可信来源，如云学堂服务器免登）

### 监控

- 请求日志与访问记录在网关层统一采集
- 配合 Uptime / Sentry 完成服务可用性与错误监控（见 [应用监控](../03_开发工具/02_应用监控.md)）

## 灾备切换

厦门 / 湖北两地 Kong 网关对等部署，预置相同的业务路由规划：

- 日常状态：两地 Upstream 均指向厦门本地后端服务
- 灾难切换：管理员手动修改湖北 Kong 的 Upstream 地址，将流量切入湖北本地重建的服务集群

详见 [灾备规划方案](../../02_方案/基础设施/灾备规划方案.md)。

## 相关文档

- [权限服务](03_权限服务.md) — auth-check 插件详细配置
- [API 规范](../02_开发规范/02_API规范.md) — URL 前缀与路由约定
- [服务体系](01_服务体系.md) — 整体架构与数据流向
