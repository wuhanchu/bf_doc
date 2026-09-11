# AGENTS.md

纯 Markdown 文档仓库（保沣集团手册），无代码、无构建/测试命令。验证方式 = 检查相对链接和图片引用是否正确。

## 结构（Nextcloud 惯例：文件夹即文档）

- 每个文档 = 一个文件夹：`NN_主题/Readme.md`（+ 该文档自己的 `attach/`），Readme.md 首字母大写
- `知识库/<分类>/<NN_主题>/Readme.md`：技术架构（含开发规范）、开发工具、运维管理、办公协作
- `操作文档/<系统>/<NN_主题>/Readme.md`：按系统组织的使用文档；LMS_物流管理 下分 `对内/`、`对外/` 两级（文档名 = `业务线_角色`）
- 每层可有一个 `Readme.md` 作为该文件夹的索引/说明（如系统级索引）
- 新增文档：建 `NN_中文标题/` 文件夹，内放 `Readme.md`；编号沿用同级现有顺序
- 文档内不加 YAML front matter（曾试过 `typora-copy-images-to`，因 Nextcloud 网页端显示脏已移除）；Typora 图片落 `attach/` 靠各机器全局偏好设置

## 附件

- 附件放**所属文档文件夹**的 `attach/` 子文件夹，用相对路径引用：`![描述](attach/xxx.png)`
- 分类/系统级 `Readme.md` 的附件放该层级的 `attach/`
- 文件名不能含空格（会破坏 markdown 链接解析）
- 命名遵循 `模块_描述` 格式，英文小写；参考同目录现有附件风格

## 同步到 Nextcloud

- `script/sync_nextcloud.sh [文件夹名...]`：`rsync --delete --inplace` 完全镜像到 `.知识库/`
  - 目标须已存在同名文件夹（如 公共操作 会被跳过）；**目标文件夹内多余文件会被删除**，未同步的顶层文件夹不受影响
  - `--inplace` 原地覆写，保证 Nextcloud 共享链接不失效
  - 改完文档跑一次即可；不带参数 = 全量，可传单个文件夹或 `知识库`/`操作文档`（自动展开子文件夹）
  - 跨机器：自动探测 macOS/Linux 的 Nextcloud 目录，探测不到或有多候选（如重连产生的 `xxx (日期)` 后缀文件夹）时 `export NEXTCLOUD_DST=...` 指定；Windows 须用 WSL（Git Bash 无 rsync）

## 其他

- `opencode.json` 仅配置 browseros-neo MCP，无其他仓库级配置
- 历史迁移（Obsidian → 本仓库）已完成，方法见 git 历史
