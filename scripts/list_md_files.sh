#!/bin/bash
# 查找所有 .md 或 .mdx 檔案，排除 PROGRESS.md 以及已經翻譯好的檔案
find . -type f \( -name "*.md" -o -name "*.mdx" \) \
  ! -name "PROGRESS.md" \
  ! -name "*_zh_TW.md" \
  ! -name "*_zh_TW.mdx" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/vendor/*" \
  ! -path "*/.vscode/*" \
  ! -path "*/.github/*"
