# 配置範例：工具篩選

演示使用 `availableTools` 白名單進行高級工具篩選。這會將代理限制在僅指定的唯讀工具，並刪除所有其他工具（bash、edit、create_file 等）。

Copilot SDK 支援兩種互補的篩選機制：

- **`availableTools`** (白名單) — 僅列出的工具可用。所有其他工具將被刪除。
- **`excludedTools`** (黑名單) — 所有工具皆可用，*除了* 列出的工具。

此範例測試使用 `["grep", "glob", "view"]` 的 **白名單** 方法。

## 每個範例的操作內容

1. 建立一個具有 `availableTools: ["grep", "glob", "view"]` 且 `systemMessage` 為 `replace` 模式的會話
2. 發送：_"您有哪些可用的工具？請列出每個工具的名稱。"_
3. 列印回應 —— 回應應僅列出 grep、glob 和 view

## 配置

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `availableTools` | `["grep", "glob", "view"]` | 僅將唯讀工具列入白名單 |
| `systemMessage.mode` | `"replace"` | 完全替換預設的系統提示詞 |
| `systemMessage.content` | 自訂提示詞 | 指示代理列出其可用的工具 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進制檔案（自動偵測或設定 `COPILOT_CLI_PATH`）和 `GITHUB_TOKEN`。

## 驗證

驗證腳本檢查：
- 回應中提到了至少一個白名單工具 (grep, glob 或 view)
- 回應中 **沒有** 提到排除的工具 (bash, edit 或 create_file)
