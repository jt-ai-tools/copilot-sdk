#!/bin/bash
# 檢查是否所有 .md 或 .mdx 都有對應的 _zh_TW 版本
MISSING=0
FILES=$(./scripts/list_md_files.sh)

for f in $FILES; do
    EXT="${f##*.}"
    BASE="${f%.*}"
    ZH_FILE="${BASE}_zh_TW.${EXT}"
    if [ ! -f "$ZH_FILE" ]; then
        echo "Missing: $ZH_FILE"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -eq 0 ]; then
    echo "All files translated!"
    exit 0
else
    echo "Total missing: $MISSING"
    exit 1
fi
