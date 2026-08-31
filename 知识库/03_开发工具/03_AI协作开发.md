# AI 协作开发

## 概述

AI 编程助手可辅助代码生成、重构、调试等任务，通过 MCP 协议集成外部工具扩展能力。

| 工具 | 类型 | 用途 |
|------|------|------|
| OpenCode | 终端 AI 助手 | 代码生成、重构、调试 |
| Claude Code | 终端 AI 助手 | Claude 模型编程助手 |
| Cursor | IDE 插件 | VS Code 集成 AI 编程 |
| CodeGraph | 代码索引工具 | 语义搜索、依赖分析 |

---

## OpenCode

### 简介

OpenCode 是基于终端的 AI 编程助手，支持 TUI、Web 界面和 Headless 服务器模式。

### 安装

```bash
# macOS
brew install opencode

# npm
npm install -g opencode

# 从源码
git clone https://github.com/opencode-ai/opencode
cd opencode
go build -o opencode
```

### 快速开始

```bash
# 在项目目录启动
opencode

# 直接提问
opencode "帮我重构这个函数"

# 启动 Web 界面
opencode web --port 17783

# 启动 Headless 服务器
opencode serve --port 17783

# 连接到运行中的服务器
opencode attach http://localhost:17783
```

### 配置

配置文件：`~/.config/opencode/opencode.json`

```json
{
  "provider": "anthropic",
  "model": "claude-sonnet-4-20250514",
  "mcp": {}
}
```

| 字段 | 说明 | 示例 |
|------|------|------|
| `provider` | AI 提供商 | `anthropic` / `openai` |
| `model` | 模型名称 | `claude-sonnet-4-20250514` |
| `mcp` | MCP 服务器配置 | 见下方 |

### MCP 服务器配置

```json
{
  "mcp": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-filesystem"]
    },
    "codegraph": {
      "command": "codegraph",
      "args": ["serve", "--mcp"],
      "enabled": true,
      "type": "local"
    }
  }
}
```

### 使用示例

```
> 帮我写一个 Express API

> 读取 src/main.ts 并解释逻辑

> 修复这个 bug

> 重构这个函数，提高可读性

> 参考 src/utils.ts 的风格，写一个新工具函数
```

---

## CodeGraph

### 简介

为 AI 编程工具提供预索引的代码知识图谱，减少 token 消耗和工具调用。

- ~25% 更便宜 · ~62% 更少工具调用 · 100% 本地
- 支持 20+ 语言
- 自动监听文件变化并同步索引

### 安装

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh

# 或 npm
npm i -g @colbymchenry/codegraph
```

### 初始化项目

```bash
cd your-project
codegraph init -i    # 初始化 + 建立索引
```

- `codegraph init`：创建 `.codegraph/` 目录
- 加 `-i`：同时构建初始索引
- 之后代码变更会**自动同步**

### 常用命令

```bash
codegraph init -i              # 初始化并建索引
codegraph index                # 重建完整索引
codegraph sync                 # 增量更新索引
codegraph status               # 查看索引状态
codegraph query "关键词"        # 搜索符号
codegraph files                # 查看文件结构
codegraph context "任务描述"    # 为 AI 构建上下文
codegraph callers <符号>        # 查找调用者
codegraph callees <符号>        # 查找被调用者
codegraph impact <符号>         # 影响分析
```

### OpenCode 集成

**自动配置：**

```bash
npx @colbymchenry/codegraph
# 交互式安装，选择 opencode 自动配置 MCP
```

**手动配置：**

在 `~/.config/opencode/opencode.json` 添加：

```json
{
  "mcp": {
    "codegraph": {
      "command": "codegraph",
      "args": ["serve", "--mcp"],
      "enabled": true,
      "type": "local"
    }
  }
}
```

### MCP 工具

| 工具 | 说明 |
|------|------|
| `codegraph_search` | 按名称搜索符号 |
| `codegraph_context` | 为任务构建代码上下文 |
| `codegraph_callers` | 查找调用者 |
| `codegraph_callees` | 查找被调用者 |
| `codegraph_impact` | 分析影响范围 |
| `codegraph_node` | 获取符号详情 |
| `codegraph_files` | 获取文件结构 |
| `codegraph_status` | 检查索引状态 |

### 使用示例

```
> 用 codegraph 分析登录流程的调用链

> 找到 UserService 的所有调用者

> 修改 UserRepository 前先分析影响范围
```

### 自动同步

`codegraph serve --mcp` 启动后，MCP 服务器在后台监听文件变化，变更后 2 秒自动更新索引。

特殊情况才需手动 `codegraph sync`：
- 沙盒环境禁用了 watcher
- 脚本中需要预检同步

### 卸载

```bash
codegraph uninstall          # 从所有 agent 移除配置
codegraph uninit             # 移除项目索引
```

---

## 使用建议

### 何时使用 CodeGraph

| 功能 | 需要 CodeGraph |
|------|----------------|
| 代码生成/重构 | ❌ 不需要 |
| 文件读写 | ❌ 不需要 |
| 对话问答 | ❌ 不需要 |
| 语义搜索 | ✅ 需要 |
| 依赖分析 | ✅ 需要 |
| 符号查找 | ✅ 需要 |

### 最佳实践

1. **新项目**：首次使用 `codegraph init -i` 建立索引
2. **大型代码库**：使用 CodeGraph 加速代码理解
3. **重构前**：用 `codegraph impact` 分析影响范围
4. **调试时**：用 `codegraph callers` 追踪调用链

---

## 参考

- [OpenCode GitHub](https://github.com/opencode-ai/opencode)
- [CodeGraph GitHub](https://github.com/colbymchenry/codegraph)
- [Claude Code](https://claude.ai/code)
- [Cursor](https://cursor.sh)
