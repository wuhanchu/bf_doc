# 保沣手册

保沣集团技术手册，包含开发手册和办公手册两部分。

---

## 目录

| 目录 | 说明 |
|------|------|
| [知识库](知识库/) | 技术架构（含开发规范）、开发工具、运维管理、办公协作 |
| [操作文档](操作文档/) | 各系统使用文档（LMS_物流管理、DC_数据中心、公共操作） |

结构采用 Nextcloud 惯例——**文件夹即文档**：每个文档一个文件夹，`Readme.md` 是正文，`attach/` 是该文档的附件：

```
知识库/技术架构/
├── 01_服务体系/
│   ├── Readme.md
│   └── attach/
│       └── 系统服务体系_架构总览.jpeg
└── 02_应用架构/
    └── Readme.md
```

---

## 推荐编辑器：Typora

推荐用 [Typora](https://typora.io) 编辑本仓库，配置一次即可：

1. `文件 → 偏好设置 → 图像`：
   - 插入图片时选 **「复制到自定义路径」**，填 `./attach`（相对当前文档所在文件夹）
   - 勾选 **「优先使用相对路径」**
2. 之后粘贴 / 拖入图片，会自动存到**该文档自己的 `attach/`** 并生成 `![xxx](attach/xxx.png)`
3. 验证一下：拖一张图进任意 `Readme.md`，确认落到了该文档的 `attach/`（若全局设置对相对路径不生效，部分版本需在文档 YAML 里写 `typora-copy-images-to: ./attach`）
4. 路径分隔符：较新版本 Typora 生成 `/`；Windows 老版本可能产生 `\`，同步脚本（`sync_nextcloud.sh`）在每次同步前会自动把图片路径中的 `\` 规范化为 `/`。

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
script/md2pdf.sh 操作文档/公共操作/账号管理/Readme.md
```

说明：

- 依赖：pandoc（`brew install pandoc`）+ weasyprint 或 Google Chrome（本机路径，如不同改脚本头部 `CHROME` 变量）
- 图片等相对引用按源文件所在目录的 `attach/` 解析并内嵌进 PDF
- 输出位置：`export/<原相对路径>.pdf`（如 `操作文档/DC_数据中心/01_报表管理/Readme.pdf`）；`export/` 为生成物，不入库
- 未变更的 md 自动跳过；`MD2PDF_JOBS=8` 可调并行数
- 样式（A4、中文字体、表格边框、图片限宽）在 `script/pandoc-style.css`

### 同步到 Nextcloud 知识库（`script/sync_nextcloud.sh`）

把 `知识库/`、`操作文档/` **完全镜像**到 Nextcloud 的 `.知识库` 文件夹（目标位置自动探测，见下）。

```bash
# 同步全部
script/sync_nextcloud.sh

# 只同步指定系统/分类（父目录会自动展开为其中的子文件夹）
script/sync_nextcloud.sh ./操作文档/
script/sync_nextcloud.sh 技术架构
```

- `rsync --delete` 镜像：目标多余文件会被**删除**，仓库是唯一事实来源
- 目标里**存在同名文件夹才同步**，没有的自动跳过（如 公共操作）
- 增量复制（按大小和时间），且用 `--inplace` 原地覆写——内容变更不会导致 Nextcloud 共享链接失效
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

附件放在**所属文档文件夹**的 `attach/` 子文件夹，用相对路径引用：`![描述](attach/xxx.png)`。命名遵循 `模块_描述` 格式，英文一律小写，不能含空格。
