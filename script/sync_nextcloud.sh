#!/usr/bin/env bash
# 把本仓库的 知识库/ 运维管理/ 操作文档/ 整板块镜像到 Nextcloud 的 .知识库 文件夹
# 结构：文档 = <板块>/<分类或系统>/NN_主题.md；附件 = <板块>/_attach/（板块级共享）
# 规则：目标须已存在同名板块文件夹才同步；--delete 完全镜像（目标板块内多余文件会被删除）
# 用法: script/sync_nextcloud.sh [知识库|运维管理|操作文档 ...]   缺省 = 同步全部
set -uo pipefail

command -v rsync >/dev/null 2>&1 || { echo "缺少 rsync。Windows 请用 WSL 运行（Git Bash 不带 rsync）。" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || echo "提示：未找到 python3，跳过图片路径反斜杠规范化" >&2

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# 目标文件夹：可用环境变量 NEXTCLOUD_DST 覆盖；默认自动探测本机 Nextcloud 同步目录
DST=""
if [ -n "${NEXTCLOUD_DST:-}" ]; then
  DST="$NEXTCLOUD_DST"
else
  candidates=()
  re=' \([^)]*\)/'   # 客户端重连产生的 "xxx (2026-.. ..)/..." 后缀目录
  while IFS= read -r d; do
    [[ "$d" =~ $re ]] && continue
    candidates+=("$d")
  done < <(ls -d "$HOME"/Library/CloudStorage/Nextcloud-*/.知识库 "$HOME"/Nextcloud/.知识库 2>/dev/null)
  if [ ${#candidates[@]} -eq 1 ]; then
    DST="${candidates[0]}"
  elif [ ${#candidates[@]} -gt 1 ]; then
    echo "发现多个 Nextcloud 知识库目录，请指定其中一个后重试：" >&2
    printf '  export NEXTCLOUD_DST="%s"\n' "${candidates[@]}" >&2
    exit 1
  fi
fi

if [ -z "$DST" ] || [ ! -d "$DST" ]; then
  echo "未找到 Nextcloud 知识库目录。请先安装并登录 Nextcloud 客户端，" >&2
  echo "或设置目标路径后重试：export NEXTCLOUD_DST=/path/to/.知识库" >&2
  exit 1
fi

# 规范化图片路径：Windows Typora 可能生成反斜杠，统一改为 /
python3 - <<'EOF' || true
import pathlib, re
for top in ('知识库', '运维管理', '操作文档'):
    for f in pathlib.Path(top).rglob('*.md'):
        s = f.read_text()
        n = re.sub(r'(!\[[^\]]*\]\()([^)]+)(\))',
                   lambda m: m.group(1) + m.group(2).replace('\\', '/') + m.group(3), s)
        if n != s:
            f.write_text(n); print('  修正反斜杠路径:', f)
EOF

retry_rsync() {  # $@ = rsync 参数；失败重试 3 次
  local attempt
  for attempt in 1 2 3; do
    rsync "$@" && return 0
    [ "$attempt" -lt 3 ] && echo "  重试 ($attempt/3)..." >&2
    sleep 3
  done
  return 1
}

sections=()
if [ $# -gt 0 ]; then
  for p in "$@"; do
    p="${p#./}"; p="${p%/}"
    case "$p" in
      知识库|运维管理|操作文档) sections+=("$p") ;;
      *) echo "忽略未知板块: $p（仅支持 知识库 / 运维管理 / 操作文档）" >&2 ;;
    esac
  done
else
  sections=(知识库 运维管理 操作文档)
fi

copied=0
failed=()
skipped=()

echo "== 镜像同步到 $DST"
for s in "${sections[@]}"; do
  src="$ROOT/$s"
  if [ ! -d "$src" ]; then
    echo "  源不存在: $s" >&2
    failed+=("$s")
    continue
  fi
  if [ ! -d "$DST/$s" ]; then
    echo "  跳过 $s（目标无同名板块文件夹；首次使用请在 .知识库/ 下建好：知识库 运维管理 操作文档）" >&2
    skipped+=("$s")
    continue
  fi
  if retry_rsync -rtO -8 --timeout=60 --inplace --delete --exclude=.DS_Store "$src/" "$DST/$s/"; then
    echo "  已镜像 $s/（含 _attach/）"
    copied=$((copied + 1))
  else
    failed+=("$s")
  fi
done

# 知识库索引页同时放到目标根目录，方便作为入口
if [ -f "$ROOT/知识库/Readme.md" ]; then
  cp "$ROOT/知识库/Readme.md" "$DST/Readme.md" 2>/dev/null && echo "  更新 Readme.md" || echo "  跳过 Readme.md（目标根目录不可写）"
fi

echo "----"
echo "已同步 $copied 个板块"
[ ${#skipped[@]} -gt 0 ] && echo "跳过（目标无同名板块文件夹）: ${skipped[*]}"
if [ ${#failed[@]} -gt 0 ]; then
  echo "失败（网络挂载超时，可重跑）: ${failed[*]}" >&2
  exit 1
fi
