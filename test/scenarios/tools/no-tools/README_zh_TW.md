# 設定範例：無工具 (No Tools)

示範如何為 Copilot SDK 設定**零工具**以及反映無工具狀態的自定義系統提示詞。這驗證了兩件事：

1. **工具移除** — 設定 `availableTools: []` 會從代理程式的功能中移除所有內建工具（bash, view, edit, grep, glob 等）。
2. **代理程式感知** — 被替換的系統提示詞會告知代理程式它沒有工具，且代理程式的回應會確認這一點。

## 每個範例的功能

1. 建立一個 `availableTools: []` 且 `systemMessage` 為 `replace` 模式的工作階段。
2. 發送：_"你有什麼可用的工具？請列出它們。"_
3. 列印回應 — 回應應確認代理程式沒有任何工具。

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `availableTools` | `[]` (空陣列) | 允許零個工具 — 所有內建工具都會被移除 |
| `systemMessage.mode` | `"replace"` | 完全替換預設的系統提示詞 |
| `systemMessage.content` | 自定義最小化提示詞 | 告知代理程式它沒有工具，且只能以純文字回應 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 執行檔（自動偵測或設定 `COPILOT_CLI_PATH`）和 `GITHUB_TOKEN`。
