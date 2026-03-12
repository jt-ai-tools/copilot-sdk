# 功能 (Features)

這些指南涵蓋了您可以添加到 Copilot SDK 應用程式的功能。每份指南都包含所有支援語言（TypeScript、Python、Go 和 .NET）的範例。

> **剛接觸 SDK？** 請先閱讀 [入門教學](../getting-started_zh_TW.md)，然後再回來這裡添加更多功能。

## 指南 (Guides)

| 功能 | 說明 |
|---|---|
| [Hooks](./hooks_zh_TW.md) | 攔截並自訂工作階段行為 — 控制工具執行、轉換結果、處理錯誤 |
| [自訂代理 (Custom Agents)](./custom-agents_zh_TW.md) | 定義具有特定範圍工具和指令的專業子代理 |
| [MCP 伺服器](./mcp_zh_TW.md) | 整合模型內容協定 (Model Context Protocol) 伺服器以進行外部工具存取 |
| [技能 (Skills)](./skills_zh_TW.md) | 從目錄載入可重複使用的提示模組 |
| [圖片輸入](./image-input_zh_TW.md) | 將圖片作為附件傳送到工作階段 |
| [串流事件](./streaming-events_zh_TW.md) | 訂閱即時工作階段事件（40 多種事件類型） |
| [引導與排隊 (Steering & Queueing)](./steering-and-queueing_zh_TW.md) | 控制訊息傳遞 — 立即引導與循序排隊 |
| [工作階段持久化 (Session Persistence)](./session-persistence_zh_TW.md) | 在重新啟動後恢復工作階段，管理工作階段儲存 |

## 相關內容 (Related)

- [Hooks 參考](../hooks/index_zh_TW.md) — 每個 hook 類型的詳細 API 參考
- [整合](../integrations/microsoft-agent-framework_zh_TW.md) — 在其他平台（MAF 等）使用 SDK
- [疑難排解](../troubleshooting/debugging_zh_TW.md) — 當事情不如預期運作時
- [相容性](../troubleshooting/compatibility_zh_TW.md) — SDK 與 CLI 功能矩陣
