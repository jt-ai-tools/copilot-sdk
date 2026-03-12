# 設定範例：MCP 伺服器

展示如何設定 Copilot SDK 與 **MCP (Model Context Protocol) 伺服器** 整合。這驗證了 SDK 正確地將 `mcpServers` 設定傳遞給執行環境，以便透過 stdio 連接到外部工具提供者。

## 每個範例的功能

1. 檢查 `MCP_SERVER_CMD` 環境變數
2. 如果已設定，在工作階段設定中配置一個類型為 `stdio` 的 MCP 伺服器項目
3. 建立一個 `availableTools: []` 且可選包含 `mcpServers` 的工作階段
4. 發送：_"法國的首都是什麼？"_ 作為備用測試提示
5. 印出回應以及是否已設定 MCP 伺服器

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `mcpServers` | 伺服器設定映射 | 連接到公開工具的外部 MCP 伺服器 |
| `mcpServers.*.type` | `"stdio"` | 透過 stdin/stdout 與 MCP 伺服器通訊 |
| `mcpServers.*.command` | 執行檔路徑 | 要啟動的 MCP 伺服器二進位檔 |
| `mcpServers.*.args` | 字串陣列 | 傳遞給 MCP 伺服器的引數 |
| `availableTools` | `[]` (空陣列) | 無內建工具；如果可用，則使用 MCP 工具 |

## 環境變數

| 變數 | 是否必填 | 描述 |
|----------|----------|-------------|
| `COPILOT_CLI_PATH` | 否 | `copilot` 二進位檔路徑 (自動偵測) |
| `GITHUB_TOKEN` | 是 | GitHub 驗證權杖 (備用方案為 `gh auth token`) |
| `MCP_SERVER_CMD` | 否 | MCP 伺服器執行檔 — 設定後即可啟用 MCP 整合 |
| `MCP_SERVER_ARGS` | 否 | MCP 伺服器命令的空格分隔引數 |

## 執行

```bash
# 不含 MCP 伺服器 (建置 + 基本整合測試)
./verify.sh

# 使用真實的 MCP 伺服器
MCP_SERVER_CMD=npx MCP_SERVER_ARGS="@modelcontextprotocol/server-filesystem /tmp" ./verify.sh
```

需要 `copilot` 二進位檔 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
