# GitHub Copilot SDK 文件

歡迎使用 GitHub Copilot SDK 文件。無論您是正在構建第一個由 Copilot 驅動的應用程式還是正在部署到生產環境，您都可以在這裡找到所需的內容。

## 從哪裡開始

| 我想... | 前往 |
|---|---|
| **構建我的第一個應用程式** | [入門指南](./getting-started_zh_TW.md) — 包含串流傳輸和自定義工具的端到端教程 |
| **設置生產環境** | [設置指南](./setup/index_zh_TW.md) — 架構、部署模式、擴展 |
| **配置身份驗證** | [身份驗證](./auth/index_zh_TW.md) — GitHub OAuth、環境變數、BYOK |
| **為我的應用程式添加功能** | [功能](./features/index_zh_TW.md) — 鉤子 (Hooks)、自定義代理、MCP、技能 (Skills) 等 |
| **調試問題** | [疑難排解](./troubleshooting/debugging_zh_TW.md) — 常見問題及解決方案 |

## 文件地圖

### [入門指南](./getting-started_zh_TW.md)

循序漸進的教程，帶領您從零開始構建一個具有串流響應和自定義工具的功能齊全的 Copilot 應用程式。

### [設置 (Setup)](./setup/index_zh_TW.md)

如何根據您的使用場景配置和部署 SDK。

- [本地 CLI](./setup/local-cli_zh_TW.md) — 最簡單的路徑，使用您已登入的 CLI
- [捆綁 CLI](./setup/bundled-cli_zh_TW.md) — 將 CLI 與您的應用程式一起交付
- [後端服務](./setup/backend-services_zh_TW.md) — 伺服器端，透過 TCP 運行無介面 (Headless) CLI
- [GitHub OAuth](./setup/github-oauth_zh_TW.md) — 實現 OAuth 流程
- [Azure 受控識別 (Azure Managed Identity)](./setup/azure-managed-identity_zh_TW.md) — 配合 Azure AI Foundry 使用 BYOK
- [擴展與多租戶](./setup/scaling_zh_TW.md) — 水平擴展、隔離模式

### [身份驗證 (Authentication)](./auth/index_zh_TW.md)

配置用戶和服務如何透過 Copilot 進行身份驗證。

- [身份驗證概述](./auth/index_zh_TW.md) — 方法、優先級順序和範例
- [自備金鑰 (Bring Your Own Key, BYOK)](./auth/byok_zh_TW.md) — 使用您自己的 OpenAI、Azure、Anthropic 等 API 金鑰

### [功能 (Features)](./features/index_zh_TW.md)

利用 SDK 的功能進行開發的指南。

- [鉤子 (Hooks)](./features/hooks_zh_TW.md) — 攔截並自定義會話行為
- [自定義代理 (Custom Agents)](./features/custom-agents_zh_TW.md) — 定義專門的子代理
- [MCP 伺服器](./features/mcp_zh_TW.md) — 整合模型上下文協議 (Model Context Protocol) 伺服器
- [技能 (Skills)](./features/skills_zh_TW.md) — 加載可重用的提示模組
- [圖片輸入](./features/image-input_zh_TW.md) — 將圖片作為附件發送
- [串流事件](./features/streaming-events_zh_TW.md) — 即時事件參考
- [引導與隊列 (Steering & Queueing)](./features/steering-and-queueing_zh_TW.md) — 訊息傳遞模式
- [會話持久化](./features/session-persistence_zh_TW.md) — 跨重啟恢復會話

### [鉤子參考 (Hooks Reference)](./hooks/index_zh_TW.md)

每個會話鉤子的詳細 API 參考。

- [工具調用前 (Pre-Tool Use)](./hooks/pre-tool-use_zh_TW.md) — 批准、拒絕或修改工具調用
- [工具調用後 (Post-Tool Use)](./hooks/post-tool-use_zh_TW.md) — 轉換工具結果
- [用戶提示已提交 (User Prompt Submitted)](./hooks/user-prompt-submitted_zh_TW.md) — 修改或過濾用戶訊息
- [會話生命週期](./hooks/session-lifecycle_zh_TW.md) — 會話的開始和結束
- [錯誤處理](./hooks/error-handling_zh_TW.md) — 自定義錯誤處理

### [疑難排解 (Troubleshooting)](./troubleshooting/debugging_zh_TW.md)

- [調試指南](./troubleshooting/debugging_zh_TW.md) — 常見問題及解決方案
- [MCP 調試](./troubleshooting/mcp-debugging_zh_TW.md) — MCP 專用的疑難排解
- [兼容性](./troubleshooting/compatibility_zh_TW.md) — SDK 與 CLI 功能矩陣

### [可觀測性 (Observability)](./observability/opentelemetry_zh_TW.md)

- [OpenTelemetry 儀器化](./observability/opentelemetry_zh_TW.md) — 為您的 SDK 使用添加追蹤

### [整合 (Integrations)](./integrations/microsoft-agent-framework_zh_TW.md)

將 SDK 與其他平台和框架配合使用的指南。

- [Microsoft Agent Framework](./integrations/microsoft-agent-framework_zh_TW.md) — MAF 多代理工作流
