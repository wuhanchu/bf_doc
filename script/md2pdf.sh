#!/usr/bin/env bash
# md 批量转 PDF：pandoc 生成内嵌图片的 HTML，Chrome headless 打印为 PDF
# 用法: script/md2pdf.sh [目标文件夹或 md 文件]
#   缺省目标 = 仓库根（整个仓库的 md）
#   输出     = export/<原相对路径>.pdf，目录结构与源一致
#   MD2PDF_JOBS=并行数（默认 4）；未变更的 md 自动跳过
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT="$ROOT/export"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
JOBS="${MD2PDF_JOBS:-4}"

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  TARGET="$ROOT"
elif [ ! -e "$TARGET" ]; then
  TARGET="$ROOT/$TARGET"
fi

if [ "${1:-}" = "--one" ]; then
  # 内部入口：转换单个文件（由下方 xargs 并行调用）
  shift
  md="$1"
  rel="${md#"$ROOT"/}"
  out="$EXPORT/${rel%.md}.pdf"
  # md 与同目录 attach/ 都没有比 PDF 新 → 跳过
  if [ -f "$out" ] && [ "$out" -nt "$md" ] \
     && ! find "$(dirname "$md")/attach" -newer "$out" -print -quit 2>/dev/null | grep -q .; then
    echo "SKIP $rel"
    exit 0
  fi
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  CSS_FILE="$ROOT/script/pandoc-style.css"
  mkdir -p "$(dirname "$out")"
  # 引擎：优先 weasyprint（快），否则 Chrome headless
  WP="$(command -v weasyprint || true)"
  if [ -z "$WP" ] && [ -x "$HOME/Library/Python/3.13/bin/weasyprint" ]; then
    WP="$HOME/Library/Python/3.13/bin/weasyprint"
  fi
  if [ -n "$WP" ]; then
    pandoc "$md" --from markdown \
      --pdf-engine="$WP" --css="$CSS_FILE" \
      --resource-path="$(dirname "$md")" \
      --metadata pagetitle="$rel" \
      -o "$out"
    echo "OK   $rel"
    exit 0
  fi
  html="$tmp/page.html"
  pandoc "$md" \
    --from markdown \
    --embed-resources --standalone \
    --css="$CSS_FILE" \
    --resource-path="$(dirname "$md")" \
    --metadata pagetitle="$rel" \
    -o "$html"
  if "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
      --print-to-pdf="$out" "file://$html" 2>/dev/null; then
    echo "OK   $rel"
  else
    echo "FAIL $rel" >&2
    exit 1
  fi
  exit 0
fi

# ---- 批量模式：收集文件 → xargs 并行调用自身 --one ----
mkdir -p "$EXPORT"

if [ -f "$TARGET" ] && [[ "$TARGET" == *.md ]]; then
  "$0" --one "$TARGET" 2>&1
else
  find "$TARGET" -name '*.md' \
    -not -path '*/.git/*' -not -path "$EXPORT/*" -not -path '*/attach/*' -print0 \
    | xargs -0 -P "$JOBS" -n 1 "$0" --one 2>&1 | sort
fi
echo "----"
echo "完成。输出目录: ${EXPORT}（MD2PDF_JOBS=$JOBS 控制并行数）"
