# 設定範例：無限工作階段 (Infinite Sessions)

示範如何為 Copilot SDK 配置啟用的 **無限工作階段 (infinite sessions)**，它使用內容壓縮來允許工作階段在超出模型的內容視窗限制後繼續進行。

## 測試內容

1. **配置接受度** — 具有壓縮閾值的 `infiniteSessions` 配置被伺服器接受且無錯誤。
2. **工作階段連續性** — 在啟用無限工作階段的情況下，多條訊息發送與回應接收均成功。

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `infiniteSessions.enabled` | `true` | 為工作階段啟用內容壓縮 |
| `infiniteSessions.backgroundCompactionThreshold` | `0.80` | 在內容使用率達到 80% 時觸發背景壓縮 |
| `infiniteSessions.bufferExhaustionThreshold` | `0.95` | 在內容使用率達到 95% 時強制進行壓縮 |
| `availableTools` | `[]` | 無工具 —— 保持較小的內容以供測試 |
| `systemMessage.mode` | `"replace"` | 取代預設系統提示 |

## 運作原理

啟用 `infiniteSessions` 時，伺服器會監控內容視窗的使用量。隨著對話增長：

- 在 `backgroundCompactionThreshold` (80%) 時，伺服器開始在背景壓縮較舊的訊息。
- 在 `bufferExhaustionThreshold` (95%) 時，在處理下一條訊息之前會強制進行壓縮。

這允許工作階段無限期地執行，而不會觸及內容限制。

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |
| `python/` | `github-copilot-sdk` | Python |
| `go/` | `github.com/github/copilot-sdk/go` | Go |

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進位檔案 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
