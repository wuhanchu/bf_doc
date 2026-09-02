# AGENTS.md

纯 Markdown 文档仓库（保沣集团手册），无代码、无构建/测试命令。验证方式 = 检查相对链接和图片引用是否正确。

## 结构

- `知识库/<分类>/NN_主题.md`：技术架构（含开发规范）、开发工具、运维管理、办公协作
- `操作文档/<系统>/`：按系统组织的使用文档，每个系统有 `README.md` 作为索引；LMS_物流管理 下分 `对内/`、`对外/` 两个子文件夹（文档名 = `业务线_角色.md`，attach/ 随侧存放）
- 文档文件名统一 `NN_中文标题.md` 编号前缀；新增文档沿用同目录现有编号顺序

## 附件

- 附件放所属目录的 `attach/` 子文件夹，用相对路径引用：`![描述](attach/xxx.png)`
- 文件名不能含空格（会破坏 markdown 链接解析）
- 命名遵循 README：`模块_描述` 格式，英文小写；参考同目录现有附件风格

## 从 Obsidian 迁移

- 源：`/Users/wuhanchu/obsidian/notebook/01_projects/baofeng/` 下的 vault
- Obsidian 附件存于 vault 级 `99_attachments/`，须复制到目标 `attach/`
- wiki 链接 `![[path/image.png]]` 必须改写为 `![描述](attach/xxx.png)`；迁移后 grep 检查 `\[\[` 无残留

## 其他

- `opencode.json` 仅配置 browseros-neo MCP，无其他仓库级配置
