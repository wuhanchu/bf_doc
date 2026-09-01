# 数据库开发

## 通用规则

### 表命名

- 使用小写字母 + 下划线（snake_case）
- 表名具有业务含义，使用名词形式，不使用复数
- 关联表用两个表名下划线连接：`booking_quotation`、`inquiry_supplier`
- 字典字段用字符串类型，在 comment 中写明字典范围

### 字段命名

- 使用小写字母 + 下划线（snake_case）
- 主键统一用 `id`（不加表名前缀）
- 外键用 `关联表名单数_id`：`booking_id`、`quotation_id`
- 布尔字段用 `is_` 前缀：`is_active`、`is_deleted`
- 时间字段用 `_time` 后缀：`create_time`、`update_time`
- 状态字段统一用 `state`（不用 `status`）

### 标准字段

每个表必须包含：

| 字段 | 注释 |
|------|------|
| `id` | 主键ID |
| `create_time` | 创建时间 |
| `update_time` | 更新时间 |
| `operator_account` | 操作账号 |

类型表或分组表需增加 `key` 编码字段用于外键关联（ID 会随修改变化）。

### 关联表

- 多对多关系用关联表，包含两个关联字段
- 关联关系属性（如成交价格、数量）放关联表
- 外键字段加索引

### 注释格式

`字段说明|业务规则|字典范围`，字典范围可选。

标准字段注释固定格式：
- 主键：`主键ID`
- 时间：`创建时间`、`更新时间`
- 操作人：`操作账号`

状态字段必须包含所有状态值：

```sql
COMMENT ON COLUMN example.state IS '状态|init:初始,active:启用,disabled:禁用';
```

其他示例：
- `客户名称` — 简单说明
- `订单类型|normal:普通,vip:加急` — 有字典

---

## PostgreSQL

### 字段类型

| 用途 | 类型 |
|------|------|
| 主键 | INTEGER GENERATED ALWAYS AS IDENTITY |
| 外键 | INTEGER |
| 文本 | TEXT |
| 整数 | INTEGER |
| 小数 | NUMERIC |
| 布尔 | BOOLEAN DEFAULT false |
| 时间 | TIMESTAMP |
| 数组 | TEXT[] / INTEGER[] |
| JSON | JSONB |
| 状态 | TEXT DEFAULT 'init' |

### 创建表模板

```sql
CREATE TABLE {schema}.{table_name} (
    id INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    -- 业务字段
    field1 TEXT,
    field2 INTEGER,
    field3 NUMERIC,
    field4 BOOLEAN DEFAULT false,
    field5 JSONB,
    field6 TEXT[],
    -- 状态字段
    state TEXT NOT NULL DEFAULT 'init',
    -- 基础字段
    create_time TIMESTAMP DEFAULT NOW(),
    update_time TIMESTAMP DEFAULT NOW(),
    operator_account TEXT
);

COMMENT ON TABLE {schema}.{table_name} IS '表中文名';
COMMENT ON COLUMN {schema}.{table_name}.id IS '主键ID';
COMMENT ON COLUMN {schema}.{table_name}.field1 IS '字段说明|业务规则';
COMMENT ON COLUMN {schema}.{table_name}.state IS '状态|init:初始,active:启用';

CREATE INDEX idx_{table_name}_field1 ON {schema}.{table_name}(field1);
```

主键用 `GENERATED ALWAYS AS IDENTITY`，不用 `SERIAL PRIMARY KEY`。

---

## SQL Server

### 字段类型

| 用途 | 类型 |
|------|------|
| 主键 | INT IDENTITY(1,1) |
| 外键 | INT |
| 文本 | NVARCHAR(MAX) 或 NVARCHAR(n) |
| 整数 | INT |
| 小数 | DECIMAL(18,2) |
| 布尔 | BIT DEFAULT 0 |
| 时间 | DATETIME |
| JSON | NVARCHAR(MAX) |
| 状态 | NVARCHAR(50) DEFAULT 'init' |

### 创建表模板

```sql
CREATE TABLE {schema}.{table_name} (
    id INT IDENTITY(1,1) NOT NULL,
    -- 业务字段
    field1 NVARCHAR(MAX),
    field2 INT,
    field3 DECIMAL(18,2),
    field4 BIT DEFAULT 0,
    field5 NVARCHAR(MAX),
    -- 状态字段
    state NVARCHAR(50) NOT NULL DEFAULT 'init',
    -- 基础字段
    create_time DATETIME DEFAULT GETDATE(),
    update_time DATETIME DEFAULT GETDATE(),
    operator_account NVARCHAR(100)
);

EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'表中文名',
    @level0type = N'SCHEMA', @level0name = '{schema}',
    @level1type = N'TABLE',  @level1name = '{table_name}';

EXEC sp_addextendedproperty
    @name = N'MS_Description', @value = N'字段说明',
    @level0type = N'SCHEMA', @level0name = '{schema}',
    @level1type = N'TABLE',  @level1name = '{table_name}',
    @level2type = N'COLUMN', @level2name = 'field1';
```
