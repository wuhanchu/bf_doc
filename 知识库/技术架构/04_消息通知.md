# 消息通知

统一消息通知服务（message_service），基于 Flask + Apprise，支持 70+ 种通知渠道，并提供自定义通知提供者扩展机制。

## 功能特性

- **统一通知接口** — 单一 API 支持多渠道消息发送
- **同步/异步发送** — 支持立即发送和后台队列处理（APScheduler 每 10 秒轮询）
- **自动重发** — 失败通知支持重试，记录每次发送结果
- **附件支持** — 通过 MinIO 存储和发送消息附件
- **发送追踪** — 详细记录每条通知的发送状态和失败原因

## 通知渠道

### Apprise 原生渠道（70+）

邮件（mailto://）、Telegram、Discord、Slack、Webhook、SMS 等。

### 自定义渠道

| 渠道 | URL 格式 | 说明 |
|------|----------|------|
| 微信公众号模板消息 | `wechat-oa://{template_id}?to_type=loginid&to={账号}` | loginid 自动转换为 openid |
| 云之家 | `yunzhijia://{location}?account={名称}&to_type=emp_no&to={员工号}` | emp_no 自动转换为 openid；location：xm 厦门 / hb 湖北 |
| 预配置渠道 | `schema://{schema_key}?to={接收者}` | 通过数据库配置发送渠道，避免代码中暴露完整 URL |

### 集成功能

- **云学堂集成** — 接收云学堂通知并自动转发至云之家
- **微信公众号模板查询** — `GET /wechat/templates` 获取可用模板列表

## 发送通知

```
POST /notify
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| urls | array | 是* | 通知 URL 列表（与 channel_key 二选一） |
| channel_key | string | 是* | 预配置渠道 key（与 urls 二选一） |
| title | string | 否 | 消息标题 |
| body | string | 否 | 消息内容 |
| sync | boolean | 否 | 是否同步发送（默认 false 异步） |
| data | object | 否 | 微信模板消息数据 |
| attach | array | 否 | 附件路径列表（MinIO 相对路径） |

**示例：**

```bash
# 云之家通知（emp_no 自动转换）
curl -X POST http://localhost:5000/notify \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["yunzhijia://xm?account=厦门&to_type=emp_no&to=1001"],
    "title": "系统通知",
    "body": "今晚22点系统升级",
    "sync": false
  }'

# 微信公众号模板消息（loginid 自动转换）
curl -X POST http://localhost:5000/notify \
  -H "Content-Type: application/json" \
  -d '{
    "urls": ["wechat-oa://模板ID?to_type=loginid&to=user001"],
    "title": "告警通知",
    "body": "CPU使用率超过90%",
    "sync": true,
    "data": {"thing1": {"value": "服务器告警"}}
  }'
```

## 通知流程

```
请求 → 参数校验 → Notify 记录创建
                     ↓
          同步：立即发送
          异步：定时任务轮询（10秒）
                     ↓
          URL 路由（Apprise / 自定义 Provider）
                     ↓
          emp_no/loginid 转换为 openid
                     ↓
          发送通知 → NotifyData 明细记录
```

1. **参数验证** — Marshmallow Schema 校验请求参数
2. **记录创建** — 创建 Notify 主记录保存到数据库
3. **发送方式** — 同步（sync=true）立即调用；异步由 APScheduler 每 10 秒轮询处理
4. **URL 路由** — Apprise 原生 URL 走 Apprise；自定义 URL 走 CustomProviderManager
5. **ID 转换** — `yunzhijia://` 的 emp_no、`wechat-oa://` 的 loginid 自动转换为 openid
6. **结果记录** — 每条通知的发送结果写入 NotifyData 明细表

## 数据库表

| 表名 | 说明 |
|------|------|
| notify | 通知主表 |
| notify_data | 发送明细表（记录每次发送结果） |
| notify_channel | 渠道配置表 |
| notify_schema | 预配置模板表 |

## 技术栈

- **框架**：Flask + flask_frame
- **通知**：Apprise + 自定义 Provider
- **调度**：APScheduler
- **数据库**：PostgreSQL（schema=message）
- **对象存储**：MinIO
- **错误监控**：Sentry

## Apprise 无状态服务

底层集成的 Apprise API 独立服务，可直接通过 URL 发送通知，无需预先配置。

| 项目 | 说明 |
|------|------|
| 地址 | 见 [开发服务地址](../README.md#开发服务地址) |
| 版本 | v1.9.2 |

### 无状态通知

```
POST /notify/
```

| 参数 | 说明 |
|------|------|
| urls | Apprise URL(s)，多个用逗号或空格分隔 |
| body | 消息内容（必填） |
| title | 消息标题（可选） |
| type | 消息类型：info（默认）、success、warning、failure |

```bash
curl -X POST "http://192.168.51.92:38005/notify" \
  -d "urls=mailto://user@example.com" \
  -d "body=测试消息" \
  -d "title=系统通知"
```

### 持久化配置

将配置持久化存储，后续通过 KEY 调用：

| 操作 | 接口 | 说明 |
|------|------|------|
| 添加 | `POST /add/KEY` | 参数：urls 或 config + format（yaml/text） |
| 发送 | `POST /notify/KEY` | 通过已存储的配置发送 |
| 删除 | `POST /del/KEY` | 删除配置 |
| 获取 | `GET /get/KEY` | 供 Apprise CLI 远程加载 |

**KEY 命名规则：** 仅支持 `-` 和 `_`，至少 2 个字母/数字开头，最长 64 字符。

**项目管理约定：** 所有自研服务上线时需在 Apprise 持久化配置中创建以项目缩写命名的 KEY（如 `lms_notify`），作为该服务的通知配置入口，统一管理通知渠道并通过 KEY 直接调用。

## 参考

- [Apprise Wiki](https://github.com/caronc/apprise/wiki)
- [支持的 notify 服务列表](https://github.com/caronc/apprise/wiki/Support_Notification_Services)
