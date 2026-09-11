# API 开发规范

我们参考了 PostgREST 的 API 规范，尽量保持风格的一致性。

## 原则

- URL 中不能有动词
- URL 结尾不应该包含斜杠 "/"
- URL 路径中首选小写字母
- URL 路径名词均为复数
- URL 实体名称需要和数据库实体名称保持一致

## 请求

所有后台服务的请求需要加上 api 前缀：

```
api.xxx.com/api/
```

服务实现不需要增加这个前缀，由 API 网关统一配置。

### 版本

API 的版本号和客户端 APP 的版本号无关，提供 v1、v2 之类的版本号。版本号只允许枚举，不允许判断区间。

```
api.xxx.com/api/v1/users
```

### 方法

- GET：检索资源
- POST：创建资源
- PUT：创建或替换资源
- PATCH：部分更新资源
- DELETE：删除资源

### Path 设计

基础 CRUD：

- GET /articles：文章列表
- GET /articles/{id}：文章详情
- POST /articles：创建文章
- PUT /articles/{id}：修改文章
- DELETE /articles/{id}：删除文章

子资源（使用最短路径，不要嵌套过深）：

- GET /articles/{id}/comments：某篇文章的评论列表
- POST /articles/{id}/comments：在某篇文章中创建评论
- GET /comments/{id}：获取评论
- PUT /comments/{id}：修改评论
- DELETE /comments/{id}：删除评论

复杂场景：

- GET /article/detail?article_id=1：详情（有更具体的信息）
- POST /article/attach?article_id=1：附件上传

### 参数

分页：

```
/api/v1/users/?offset=10&limit=10
```

排序（- 表示降序）：

```
/api/v1/users/?sort=-create_date
/api/v1/users/?sort=-create_date,update_date
```

资源字段查询：

```
/api/v1/users/?gender=1
```

## 查询操作

查询、删除和更新操作中，支持在 URL 中对实体字段使用操作符表达式来准确定位需要操作的对象。

### 操作符

| 操作符 | 说明 | 示例 |
|--------|------|------|
| eq | 等于（默认） | `?name=eq.john` |
| neq | 不等于 | `?name=neq.john` |
| gt | 大于 | `?age=gt.18` |
| gte | 大于等于 | `?age=gte.18` |
| lt | 小于 | `?age=lt.13` |
| lte | 小于等于 | `?age=lte.13` |
| like | 模式匹配 | `?name=like.*john*` |
| ilike | 不区分大小写匹配 | `?name=ilike.*john*` |
| is | 精确匹配（用于布尔值） | `?student=is.true` |
| in | 包含在列表中 | `?id=in.(1,2,3)` |
| and | 逻辑与 | `and=(age.gte.18,student=is.true)` |
| or | 逻辑或 | `or=(age.lt.13,age.gt.65)` |

### 翻页

支持 URL 参数 `limit` 和 `offset` 进行翻页操作：

```
/api/v1/users/?offset=10&limit=10
```

### 数据总数

在请求报头加入 `Prefer: count=exact` 来统计总数，返回报头中会在 `Content-Range` 中返回对应的数量。

请求报文：

```http
GET /bigtable?limit=20&offset=0 HTTP/1.1
Prefer: count=exact
```

返回报文：

```http
HTTP/1.1 206 Partial Content
Content-Range: 0-19/3573458
```

说明数据返回的是索引 0-19 的数据，总数量为 3573458。

## 新增

新增操作使用 POST 方法。

### 批量新增

在 body 中传入数组，进行批量新增操作：

```http
POST /table_name HTTP/1.1
[{ "col1": "value1", "col2": "value2" }]
```

### 新增或修改（Upsert）

如果存在批量操作，需要判断主键是否存在。存在则更新，不存在则新增。在报头中加入 `Prefer: resolution=merge-duplicates`，系统会根据传入数据自动新增或修改。

```http
POST /employees HTTP/1.1
Prefer: resolution=merge-duplicates
[
  { "id": 1, "name": "Old employee 1", "salary": 30000 },
  { "id": 2, "name": "Old employee 2", "salary": 42000 },
  { "name": "New employee 3", "salary": 50000 }
]
```

如果使用其他字段来作为修改主键，需要带入 URL 参数 `on_conflict`：

```http
POST /employees?on_conflict=name HTTP/1.1
Prefer: resolution=merge-duplicates
[
  { "name": "Old employee 1", "salary": 40000 },
  { "name": "Old employee 2", "salary": 52000 },
  { "name": "New employee 3", "salary": 60000 }
]
```

## 修改

更新操作使用 PATCH 方法，支持在 URL 中使用查询操作符进行批量更新。

```http
PATCH /people?age=lt.13 HTTP/1.1
{ "category": "child" }
```

## 删除

删除操作使用 DELETE 方法，支持在 URL 中使用查询操作符进行批量删除。

```http
DELETE /people?age=lt.13 HTTP/1.1
```

## 返回数据

默认情况下新增和修改操作不会返回结果数据。如果需要查看新增和修改后的数据，请在报头加入 `Prefer: return=representation` 来支持结果返回。

```http
POST /people HTTP/1.1
Prefer: return=representation
{ "category": "child" }
```

返回报文：

```http
HTTP/1.1 200
[{"id":1, "category": "child" }]
```

### Prefer 报头组合

如果需要传入多个 Prefer 的数值，请使用逗号进行间隔：

```http
POST /people HTTP/1.1
Prefer: resolution=merge-duplicates,return=representation
[{ "category": "child" }]
```

支持新增或修改的同时，也支持返回结果。

## 响应

### HTTP 状态码

- 200：请求成功
- 201：创建、修改成功
- 204：删除成功
- 400：参数错误
- 401：未登录
- 403：禁止访问
- 404：未找到
- 500：系统错误

### 返回结构

code 代表系统内具体的编码，message 代表对应的信息。

成功：

```json
{
    "code": 100,
    "message": "成功",
    "data": {}
}
```

失败：

```json
{
    "code": -1000,
    "message": "用户名或密码错误"
}
```

分页：

```json
{
    "code": 100,
    "message": "成功",
    "data": {
        "list": [],
        "total": 100
    }
}
```

## 参考

- [PostgREST](http://postgrest.org/)
- [PostgREST 查询操作](http://docs.postgrest.org/en/v13/references/api/tables_views.html)
