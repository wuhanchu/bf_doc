#!/usr/bin/env bash
# 把本仓库的 知识库/ 和 操作文档/ 同步到 Nextcloud 的 .知识库 文件夹
# 规则：目标里存在同名文件夹才复制（没有对应文件夹的跳过）；只增改、不删目标文件
# 用法: script/sync_nextcloud.sh [路径...]
#   不带参数 = 同步全部；带参数 = 只同步指定子文件夹（如 操作文档/LMS_物流管理）
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="/Users/wuhanchu/Library/CloudStorage/Nextcloud-192.168.51.56:31016-吴汉楚/.知识库"
RETRIES=3   # Nextcloud File Provider 偶发 mmap 超时，失败重试

if [ ! -d "$DST" ]; then
  echo "目标文件夹不存在: $DST" >&2
  exit 1
fi

copied=0
failed=()
skipped=()

sync_one() {  # $1=源文件夹相对路径(如 知识库/技术架构)
  local src="$ROOT/$1"
  local name
  name="$(basename "$1")"
  if [ ! -d "$DST/$name" ]; then
    skipped+=("$1")
    return
  fi
  local attempt out
  for attempt in 1 2 3; do
    out="$(rsync -rtO -8 --timeout=60 --out-format='%n' "$src/" "$DST/$name/" 2>/dev/null)"
    if [ $? -eq 0 ]; then
      printf '%s\n' "$out" | sed 's/^/  更新 /'
      copied=$((copied + 1))
      return
    fi
    echo "  $1 第 $attempt 次同步失败，重试..." >&2
    sleep 3
  done
  failed+=("$1")
}

targets=()
if [ $# -gt 0 ]; then
  for p in "$@"; do
    p="${p#./}"
    if [ ! -d "$ROOT/$p" ]; then
      echo "路径不存在: $p" >&2
      exit 1
    fi
    if [[ "$p" == 知识库/* && "$p" != 知识库/*/* ]]; then
      targets+=("$p")                                  # 知识库/<分类>
    elif [[ "$p" == 操作文档/* && "$p" != 操作文档/*/* ]]; then
      targets+=("$p")                                  # 操作文档/<系统>
    else
      while IFS= read -r d; do targets+=("${d#"$ROOT"/}"); done < <(find "$ROOT/$p" -mindepth 1 -maxdepth 2 -type d)
    fi
  done
else
  while IFS= read -r d; do targets+=("${d#"$ROOT"/}"); done < <(find "$ROOT/知识库" "$ROOT/操作文档" -mindepth 1 -maxdepth 1 -type d)
fi

echo "== 同步到 $DST"
if [ -f "$ROOT/知识库/README.md" ]; then
  cp "$ROOT/知识库/README.md" "$DST/README.md" 2>/dev/null && echo "  更新 README.md" || echo "  跳过 README.md（目标根目录不可写）"
fi
for t in "${targets[@]}"; do sync_one "$t"; done

echo "----"
echo "已同步 $copied 个文件夹"
[ ${#skipped[@]} -gt 0 ] && echo "跳过（目标无同名文件夹）: ${skipped[*]}"
if [ ${#failed[@]} -gt 0 ]; then
  echo "失败（网络挂载超时，可重跑）: ${failed[*]}" >&2
  exit 1
fi
