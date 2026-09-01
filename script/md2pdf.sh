#!/usr/bin/env bash
# md 批量转 PDF：pandoc 生成内嵌图片的 HTML，Chrome headless 打印为 PDF
# 用法: script/md2pdf.sh [目标文件夹或 md 文件]
#   缺省目标 = 仓库根（整个仓库的 md）
#   输出     = export/<原相对路径>.pdf，目录结构与源一致
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT="$ROOT/export"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ---- 样式（A4、中文字体、表格边框、图片限宽）----
CSS='@page { size: A4; margin: 18mm 15mm; }
body { font-family: "PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif; font-size: 11pt; line-height: 1.6; color: #222; }
h1 { font-size: 1.6em; border-bottom: 2px solid #2f6fad; padding-bottom: 6px; }
h2 { font-size: 1.3em; border-bottom: 1px solid #ccc; padding-bottom: 4px; margin-top: 1.6em; }
h3 { font-size: 1.15em; }
table { border-collapse: collapse; width: 100%; margin: 8px 0; }
th, td { border: 1px solid #999; padding: 5px 8px; text-align: left; word-break: break-word; }
th { background: #f2f6fa; }
img { max-width: 100%; }
code { background: #f5f5f5; padding: 1px 4px; border-radius: 3px; font-size: 0.9em; }
pre { background: #f5f5f5; padding: 8px; overflow-x: auto; }
blockquote { border-left: 4px solid #2f6fad; margin-left: 0; padding-left: 12px; color: #555; }'

TMPDIR_MD="$(mktemp -d)"
CSS_FILE="$TMPDIR_MD/style.css"
printf '%s\n' "$CSS" > "$CSS_FILE"
trap 'rm -rf "$TMPDIR_MD"' EXIT

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  TARGET="$ROOT"
elif [ ! -e "$TARGET" ]; then
  TARGET="$ROOT/$TARGET"
fi

if [ -f "$TARGET" ] && [[ "$TARGET" == *.md ]]; then
  MD_FILES="$TARGET"
else
  MD_FILES="$(find "$TARGET" -name '*.md' \
    -not -path '*/.git/*' -not -path "$EXPORT/*" -not -path '*/attach/*' | sort)"
fi

count=0
fail=0
for md in $MD_FILES; do
  rel="${md#"$ROOT"/}"
  out="$EXPORT/${rel%.md}.pdf"
  mkdir -p "$(dirname "$out")"
  html="$TMPDIR_MD/$(echo "$rel" | tr '/' '_').html"

  pandoc "$md" \
    --from markdown \
    --embed-resources --standalone \
    --css="$CSS_FILE" \
    --resource-path="$(dirname "$md")" \
    --metadata pagetitle="$rel" \
    -o "$html"

  if "$CHROME" --headless --disable-gpu --no-pdf-header-footer \
      --print-to-pdf="$out" "file://$html" 2>/dev/null; then
    count=$((count + 1))
    echo "OK  $rel -> export/${rel%.md}.pdf"
  else
    fail=$((fail + 1))
    echo "FAIL $rel" >&2
  fi
done

echo "----"
echo "完成 $count 个，失败 $fail 个。输出目录: $EXPORT"
