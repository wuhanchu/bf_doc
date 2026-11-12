# 保沣手册

保沣集团技术手册，包含开发手册和办公手册两部分。

---

## 目录

| 目录 | 说明 |
|------|------|
| [知识库](知识库/) | 技术架构（含开发规范）、开发工具、办公协作 |
| [运维管理](运维管理/) | 数据库集群与快照、能耗数据上报、容器集群管理 |
| [操作文档](操作文档/) | 各系统使用文档（LMS_物流管理、DC_数据中心、公共操作） |

结构：**一个文档 = 一个 md 文件**，附件集中在所属顶层板块的 `_attach/`：

```
知识库/
├── Readme.md               ← 知识库索引（开发服务地址、系统地址）
├── _attach/                ← 知识库全部图片
└── 技术架构/
    ├── 01_服务体系.md
    ├── 02_应用架构.md
    └── …
操作文档/
├── DC_数据中心/
│   ├── Readme.md           ← 系统索引
│   ├── 01_报表管理.md
│   └── …
└── LMS_物流管理/
    ├── Readme.md           ← 系统索引（对内/对外 文档清单）
    ├── 对内/国内物流_管理员.md
    └── 对外/国外物流_货代.md
```

---

## 推荐编辑器：Typora

推荐用 [Typora](https://typora.io) 编辑本仓库：

1. `文件 → 偏好设置 → 图像`：勾选 **「优先使用相对路径」**
2. 粘贴 / 拖入图片后，把图片文件**移到所属板块的 `_attach/`**，并把引用路径补对前缀：
   - `运维管理/xx.md` → `![](_attach/xx.png)`
   - `知识库/<分类>/xx.md`、`操作文档/<系统>/xx.md` → `![](../_attach/xx.png)`
   - `操作文档/LMS_物流管理/对内|对外/xx.md` → `![](../../_attach/xx.png)`
3. 路径分隔符：较新版本 Typora 生成 `/`；Windows 老版本可能产生 `\`，同步脚本（`sync_nextcloud.sh`）每次同步前会自动把图片路径中的 `\` 规范化为 `/`

> `_` 前缀让 `_attach/` 在文件列表置顶；不要改成 `.` 前缀（Nextcloud 会忽略点开头的文件夹，图片会裂）。

---

## 脚本

### md 转 PDF（`script/md2pdf.sh`）

把 Markdown 批量转换为 PDF，输出到 `export/` 文件夹，目录结构与源文件一致。

```bash
# 转换整个仓库
script/md2pdf.sh

# 转换指定文件夹
script/md2pdf.sh 操作文档/DC_数据中心

# 转换单个文件
script/md2pdf.sh 操作文档/公共操作/账号管理.md
```

说明：

- 依赖：pandoc（`brew install pandoc`）+ weasyprint 或 Google Chrome（本机路径，如不同改脚本头部 `CHROME` 变量）
- 图片按 md 里的相对路径（`../_attach/` 等）解析并内嵌进 PDF
- 输出位置：`export/<原相对路径>.pdf`（如 `操作文档/DC_数据中心/01_报表管理.pdf`）；`export/` 为生成物，不入库
- md 或所属板块 `_attach/` 有变更时自动重转，未变更的跳过；`MD2PDF_JOBS=8` 可调并行数
- 样式（A4、中文字体、表格边框、图片限宽）在 `script/pandoc-style.css`

### 同步到 Nextcloud 知识库（`script/sync_nextcloud.sh`）

把 `知识库/`、`运维管理/`、`操作文档/` **整板块镜像**到 Nextcloud 的 `.知识库/<板块>/`（远端结构与仓库完全一致，目标位置自动探测，见下）。

```bash
# 同步全部
script/sync_nextcloud.sh

# 只同步指定板块
script/sync_nextcloud.sh 操作文档
script/sync_nextcloud.sh 知识库 运维管理
```

- `rsync --delete` 镜像：目标板块内多余文件会被**删除**，仓库是唯一事实来源
- 目标里**存在同名板块文件夹才同步**；首次使用先在 `.知识库/` 下建好 `知识库`、`运维管理`、`操作文档` 三个文件夹，并把旧的平铺结构文件夹手动清掉
- 增量复制（按大小和时间），且用 `--inplace` 原地覆写——内容变更不会导致 Nextcloud 共享链接失效；但文件被改名/移动过的（如本次重构）链接会失效，需重新分享
- 未同步的顶层文件夹（如 `测试知识库`）不受影响

#### 换电脑 / 其他人使用

依赖：bash + rsync（python3 可选，缺失时跳过图片路径 `\` → `/` 规范化）。

1. 安装 Nextcloud 客户端并登录，确认同步文件夹里有 `.知识库`
2. `git clone` 本仓库
3. 跑 `script/sync_nextcloud.sh`，目标目录自动探测：
   - **macOS**：`~/Library/CloudStorage/Nextcloud-*/.知识库`
   - **Linux / WSL**：`~/Nextcloud/.知识库`
4. 探测不到、或发现多个候选目录（如客户端重连产生的 `xxx (2026-.. ..)` 后缀文件夹）时，脚本会拒绝猜测并列出候选，指定后重试：

   ```bash
   export NEXTCLOUD_DST="/path/to/.知识库"   # Windows WSL 示例：/mnt/c/Users/<你>/Nextcloud/.知识库
   script/sync_nextcloud.sh
   ```

> Windows 注意：必须用 **WSL** 运行（Git Bash 不带 rsync）；首次需 `sudo apt install rsync python3`。

---

## 附件

图片统一放**所属顶层板块**的 `_attach/`（`知识库/_attach/`、`运维管理/_attach/`、`操作文档/_attach/`、`项目/_attach/`），按 md 所在层级写相对路径引用：`![描述](../_attach/xxx.png)`。命名遵循 `模块_描述` 格式，英文一律小写，不能含空格；撞名时加模块/场景前缀区分（如 `lms_个人中心.png`）。
