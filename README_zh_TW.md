# GitHub Copilot CLI SDKs

![GitHub Copilot SDK](./assets/RepoHeader_01.png)

[![NPM Downloads](https://img.shields.io/npm/dm/%40github%2Fcopilot-sdk?label=npm)](https://www.npmjs.com/package/@github/copilot-sdk)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/github-copilot-sdk?label=PyPI)](https://pypi.org/project/github-copilot-sdk/)
[![NuGet Downloads](https://img.shields.io/nuget/dt/GitHub.Copilot.SDK?label=NuGet)](https://www.nuget.org/packages/GitHub.Copilot.SDK)

適用於每個應用程式的代理 (Agents)。

在您的應用程式中嵌入 Copilot 的代理工作流 —— 現已作為適用於 Python、TypeScript、Go 和 .NET 的可程式化 SDK 開放技術預覽。

GitHub Copilot SDK 公開了 Copilot CLI 背後的相同引擎：一個經過生產測試、您可以透過程式碼調用的代理執行階段。無需構建您自己的編排 —— 您定義代理行為，Copilot 負責規劃、工具調用、檔案編輯等。

## 可用的 SDK

| SDK                      | 位置           | 食譜 (Cookbook)                                   | 安裝                                      |
| ------------------------ | -------------- | ------------------------------------------------- | ----------------------------------------- |
| **Node.js / TypeScript** | [`nodejs/`](./nodejs/)   | [食譜](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk/nodejs/README.md) | `npm install @github/copilot-sdk`         |
| **Python**               | [`python/`](./python/)   | [食譜](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk/python/README.md) | `pip install github-copilot-sdk`          |
| **Go**                   | [`go/`](./go/)           | [食譜](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk/go/README.md)     | `go get github.com/github/copilot-sdk/go` |
| **.NET**                 | [`dotnet/`](./dotnet/)   | [食譜](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk/dotnet/README.md) | `dotnet add package GitHub.Copilot.SDK`   |

請參閱各個 SDK 的 README 以獲取安裝、使用範例和 API 參考。

## 開始使用

如需完整的逐步指引，請參閱 **[開始使用指南](./docs/getting-started_zh_TW.md)**。

快速步驟：

1. **安裝 Copilot CLI：**

   按照 [Copilot CLI 安裝指南](https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli) 安裝 CLI，或確保 `copilot` 在您的 PATH 中可用。

2. **使用上述命令安裝您偏好的 SDK**。

3. **參閱 SDK README** 以獲取使用範例和 API 文件。

## 架構

所有 SDK 都透過 JSON-RPC 與 Copilot CLI 伺服器通訊：

```
您的應用程式
       ↓
  SDK 用戶端
       ↓ JSON-RPC
  Copilot CLI (伺服器模式)
```

SDK 會自動管理 CLI 程序生命週期。您也可以連接到外部 CLI 伺服器 —— 有關在伺服器模式下執行 CLI 的詳細資訊，請參閱 [開始使用指南](./docs/getting-started_zh_TW.md#connecting-to-an-external-cli-server)。

## 常見問題 (FAQ)

### 我需要 GitHub Copilot 訂閱才能使用 SDK 嗎？

是的，使用 GitHub Copilot SDK 需要 GitHub Copilot 訂閱，**除非您使用 BYOK (自備金鑰)**。透過 BYOK，您可以使用來自受支援 LLM 提供者的 API 金鑰來配置 SDK，而無需 GitHub 身分驗證。對於標準用法 (非 BYOK)，請參考 [GitHub Copilot 定價頁面](https://github.com/features/copilot#pricing)，其中包括具有限制使用量的免費方案。

### SDK 使用的計費方式為何？

GitHub Copilot SDK 的計費基於與 Copilot CLI 相同的模型，每次提示都會計入您的進階請求配額。有關進階請求的更多資訊，請參閱 [GitHub Copilot 中的請求](https://docs.github.com/en/copilot/concepts/billing/copilot-requests)。

### 它是否支援 BYOK (自備金鑰)？

是的，GitHub Copilot SDK 支援 BYOK (自備金鑰)。您可以將 SDK 配置為使用來自受支援 LLM 提供者 (例如 OpenAI、Azure AI Foundry、Anthropic) 的您自己的 API 金鑰，以透過這些提供者存取模型。請參閱 **[BYOK 文件](./docs/auth/byok_zh_TW.md)** 以獲取設定說明和範例。

**注意：** BYOK 僅使用基於金鑰的身分驗證。不支援 Microsoft Entra ID (Azure AD)、受控識別和第三方身分提供者。

### 支援哪些身分驗證方法？

SDK 支援多種身分驗證方法：
- **GitHub 已登入使用者** - 使用來自 `copilot` CLI 登入的儲存 OAuth 認證
- **OAuth GitHub App** - 從您的 GitHub OAuth 應用程式傳遞使用者權杖
- **環境變數** - `COPILOT_GITHUB_TOKEN`, `GH_TOKEN`, `GITHUB_TOKEN`
- **BYOK** - 使用您自己的 API 金鑰 (無需 GitHub 驗證)

有關每種方法的詳細資訊，請參閱 **[身分驗證文件](./docs/auth/index_zh_TW.md)**。

### 我需要單獨安裝 Copilot CLI 嗎？

是的，必須單獨安裝 Copilot CLI。SDK 在伺服器模式下與 Copilot CLI 通訊以提供代理功能。

### 預設啟用了哪些工具？

預設情況下，SDK 將在相當於向 CLI 傳遞 `--allow-all` 的情況下操作 Copilot CLI，啟用所有第一方工具，這意味著代理可以執行廣泛的操作，包括檔案系統操作、Git 操作和 Web 請求。您可以透過配置 SDK 用戶端選項來啟用和停用特定工具，從而自訂工具可用性。有關工具配置的詳細資訊，請參閱各個 SDK 文件，有關可用工具列表，請參閱 Copilot CLI。

### 我可以使用自訂代理、技能或工具嗎？

是的，GitHub Copilot SDK 允許您定義自訂代理、技能和工具。您可以透過實作自己的邏輯並根據需要整合其他工具來擴展代理的功能。有關更多詳細資訊，請參閱您偏好語言的 SDK 文件。

### 是否有 Copilot 指令可以加速使用 SDK 的開發？

是的，請查看每個 SDK 的自訂指令：

- **[Node.js / TypeScript](https://github.com/github/awesome-copilot/blob/main/instructions/copilot-sdk-nodejs.instructions.md)**
- **[Python](https://github.com/github/awesome-copilot/blob/main/instructions/copilot-sdk-python.instructions.md)**
- **[.NET](https://github.com/github/awesome-copilot/blob/main/instructions/copilot-sdk-csharp.instructions.md)**
- **[Go](https://github.com/github/awesome-copilot/blob/main/instructions/copilot-sdk-go.instructions.md)**

### 支援哪些模型？

Copilot CLI 提供的所有模型在 SDK 中都受支援。SDK 還公開了一個方法，該方法將傳回可用的模型，以便在執行階段存取它們。

### SDK 是否已準備好用於生產環境？

GitHub Copilot SDK 目前處於技術預覽階段。雖然它功能齊全並可用於開發和測試，但可能尚不適合生產環境使用。

### 我該如何回報問題或要求新功能？

請使用 [GitHub Issues](https://github.com/github/copilot-sdk/issues) 頁面回報錯誤或要求新功能。我們歡迎您的回饋以幫助改進 SDK。

## 快速連結

- **[文件](./docs/index_zh_TW.md)** – 完整文件索引
- **[開始使用](./docs/getting-started_zh_TW.md)** – 開始執行的教學
- **[設定指南](./docs/setup/index_zh_TW.md)** – 架構、部署和擴展
- **[身分驗證](./docs/auth/index_zh_TW.md)** – GitHub OAuth、BYOK 等
- **[功能](./docs/features/index_zh_TW.md)** – Hook、自訂代理、MCP、技能等
- **[疑難排解](./docs/troubleshooting/debugging_zh_TW.md)** – 常見問題和解決方案
- **[食譜](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk)** – 跨所有語言常用任務的實用食譜
- **[更多資源](https://github.com/github/awesome-copilot/blob/main/collections/copilot-sdk.md)** – 額外的範例、教學和社群資源

## 非官方、社群維護的 SDK

⚠️ 免責聲明：這些是非官方的、社群驅動的 SDK，GitHub 不提供支援。使用風險自負。

| SDK           | 位置                                                              |
| --------------| ----------------------------------------------------------------- |
| **Java**      | [copilot-community-sdk/copilot-sdk-java][sdk-java]                |
| **Rust**      | [copilot-community-sdk/copilot-sdk-rust][sdk-rust]                |
| **Clojure**   | [copilot-community-sdk/copilot-sdk-clojure][sdk-clojure]          |
| **C++**       | [0xeb/copilot-sdk-cpp][sdk-cpp]                                   |

[sdk-java]: https://github.com/copilot-community-sdk/copilot-sdk-java
[sdk-rust]: https://github.com/copilot-community-sdk/copilot-sdk-rust
[sdk-cpp]: https://github.com/0xeb/copilot-sdk-cpp
[sdk-clojure]: https://github.com/copilot-community-sdk/copilot-sdk-clojure

## 貢獻

請參閱 [CONTRIBUTING.md](./CONTRIBUTING_zh_TW.md) 以獲取貢獻指南。

## 授權

MIT
