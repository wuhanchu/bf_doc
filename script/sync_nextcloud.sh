#!/usr/bin/env bash
# 把本仓库的 知识库/ 和 操作文档/ 同步到 Nextcloud 的 .知识库 文件夹
# 规则：目标里存在同名文件夹才复制（没有对应文件夹的跳过）；只增改、不删目标文件
# 用法: script/sync_nextcloud.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DST="/Users/wuhanchu/Library/CloudStorage/Nextcloud-192.168.51.56:31016-吴汉楚/.知识库"

if [ ! -d "$DST" ]; then
  echo "目标文件夹不存在: $DST" >&2
  exit 1
fi

copied=0
skipped=()

sync_one() {  # $1=源文件夹相对路径(如 知识库/技术架构)
  local src="$ROOT/$1"
  local name
  name="$(basename "$1")"
  if [ -d "$DST/$name" ]; then
    rsync -rt -8 --out-format='%n' "$src/" "$DST/$name/" | sed 's/^/  更新 /'
    copied=$((copied + 1))
  else
    skipped+=("$1")
  fi
}

echo "== 同步到 $DST"
echo "-- 知识库"
[ -f "$ROOT/知识库/README.md" ] && { cp "$ROOT/知识库/README.md" "$DST/README.md" 2>/dev/null && echo "  更新 README.md" || echo "  跳过 README.md（目标根目录不可写）"; }
for d in "$ROOT"/知识库/*/; do
  [ -d "$d" ] && sync_one "知识库/$(basename "$d")"
done

echo "-- 操作文档"
for d in "$ROOT"/操作文档/*/; do
  [ -d "$d" ] && sync_one "操作文档/$(basename "$d")"
done

echo "----"
echo "已同步 $copied 个文件夹"
if [ ${#skipped[@]} -gt 0 ]; then
  echo "跳过（目标无同名文件夹）: ${skipped[*]}"
fi
