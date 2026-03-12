# 身份驗證 (Authentication)

GitHub Copilot SDK 支持多種身份驗證方法，以適應不同的使用場景。請選擇最適合您的部署場景的方法。

## 身份驗證方法

| 方法 | 使用場景 | 是否需要 Copilot 訂閱 |
|--------|----------|-------------------------------|
| [GitHub 已登入用戶](#github-已登入用戶) | 用戶透過 GitHub 登入的互動式應用程式 | 是 |
| [OAuth GitHub 應用程式](#oauth-github-應用程式) | 透過 OAuth 代表用戶執行操作的應用程式 | 是 |
| [環境變數](#環境變數) | CI/CD、自動化、伺服器對伺服器 (Server-to-Server) | 是 |
| [自備金鑰 (BYOK)](./byok_zh_TW.md) | 使用您自己的 API 金鑰 (Azure AI Foundry, OpenAI 等) | 否 |

## GitHub 已登入用戶

這是以互動方式執行 Copilot CLI 時的預設身份驗證方法。用戶透過 GitHub OAuth 裝置流程進行身份驗證，SDK 則使用其存儲的憑據。

**運作方式：**
1. 用戶執行 `copilot` CLI 並透過 GitHub OAuth 登入
2. 憑據安全地存儲在系統鑰匙圈 (System Keychain) 中
3. SDK 自動使用存儲的憑據

**SDK 配置：**

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

// 預設：使用已登入用戶的憑據
const client = new CopilotClient();
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient

# 預設：使用已登入用戶的憑據
client = CopilotClient()
await client.start()
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
import copilot "github.com/github/copilot-sdk/go"

// 預設：使用已登入用戶的憑據
client := copilot.NewClient(nil)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

// 預設：使用已登入用戶的憑據
await using var client = new CopilotClient();
```

</details>

**適用場景：**
- 用戶直接進行交互的桌面應用程式
- 開發和測試環境
- 任何用戶可以進行互動式登入的場景

## OAuth GitHub 應用程式

使用 OAuth GitHub 應用程式透過您的應用程式對用戶進行身份驗證，並將其憑據傳遞給 SDK。這使您的應用程式能夠代表授權您應用程式的用戶發起 Copilot API 請求。

**運作方式：**
1. 用戶授權您的 OAuth GitHub 應用程式
2. 您的應用程式收到用戶存取令牌 (User Access Token，前綴為 `gho_` 或 `ghu_`)
3. 透過 `githubToken` 選項將令牌傳遞給 SDK

**SDK 配置：**

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient({
    githubToken: userAccessToken,  // 來自 OAuth 流程的令牌
    useLoggedInUser: false,        // 不使用存儲的 CLI 憑據
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient

client = CopilotClient({
    "github_token": user_access_token,  # 來自 OAuth 流程的令牌
    "use_logged_in_user": False,        # 不使用存儲的 CLI 憑據
})
await client.start()
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
import copilot "github.com/github/copilot-sdk/go"

client := copilot.NewClient(&copilot.ClientOptions{
    GithubToken:     userAccessToken,   // 來自 OAuth 流程的令牌
    UseLoggedInUser: copilot.Bool(false), // 不使用存儲的 CLI 憑據
})
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient(new CopilotClientOptions
{
    GithubToken = userAccessToken,     // 來自 OAuth 流程的令牌
    UseLoggedInUser = false,           // 不使用存儲的 CLI 憑據
});
```

</details>

**支援的令牌類型：**
- `gho_` - OAuth 用戶存取令牌
- `ghu_` - GitHub App 用戶存取令牌  
- `github_pat_` - 細粒度個人存取令牌 (Fine-grained personal access tokens)

**不支援：**
- `ghp_` - 經典個人存取令牌 (已廢棄)

**適用場景：**
- 用戶透過 GitHub 登入的 Web 應用程式
- 基於 Copilot 構建的 SaaS 應用程式
- 任何需要代表不同用戶發起請求的多用戶應用程式

## 環境變數

對於自動化、CI/CD 流水線和伺服器對伺服器場景，您可以使用環境變數進行身份驗證。

**支援的環境變數（按優先級順序）：**
1. `COPILOT_GITHUB_TOKEN` - 建議用於明確的 Copilot 使用
2. `GH_TOKEN` - 與 GitHub CLI 兼容
3. `GITHUB_TOKEN` - 與 GitHub Actions 兼容

**運作方式：**
1. 將支援的環境變數之一設置為有效的令牌
2. SDK 會自動檢測並使用該令牌

**SDK 配置：**

無需更改代碼 — SDK 會自動檢測環境變數：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

// 自動從環境變數讀取令牌
const client = new CopilotClient();
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient

# 自動從環境變數讀取令牌
client = CopilotClient()
await client.start()
```

</details>

**適用場景：**
- CI/CD 流水線 (GitHub Actions, Jenkins 等)
- 自動化測試
- 使用服務帳戶的伺服器端應用程式
- 不希望使用互動式登入的開發場景

## 自備金鑰 (Bring Your Own Key, BYOK)

BYOK 允許您使用來自模型供應商（如 Azure AI Foundry, OpenAI 或 Anthropic）的 API 金鑰。這將完全繞過 GitHub Copilot 身份驗證。

**主要優勢：**
- 無需 GitHub Copilot 訂閱
- 使用企業級模型部署
- 直接與您的模型供應商結算
- 支援 Azure AI Foundry, OpenAI, Anthropic 以及與 OpenAI 兼容的端點

**請參閱 [BYOK 文件](./byok_zh_TW.md) 以獲取完整詳情**，包括：
- Azure AI Foundry 設置
- 供應商配置選項
- 限制與注意事項
- 完整的代碼範例

## 身份驗證優先級

當有多種身份驗證方法可用時，SDK 按以下優先級順序使用它們：

1. **明確的 `githubToken`** - 直接傳遞給 SDK 構造函數的令牌
2. **HMAC 金鑰** - `CAPI_HMAC_KEY` 或 `COPILOT_HMAC_KEY` 環境變數
3. **直接 API 令牌** - 帶有 `COPILOT_API_URL` 的 `GITHUB_COPILOT_API_TOKEN`
4. **環境變數令牌** - `COPILOT_GITHUB_TOKEN` → `GH_TOKEN` → `GITHUB_TOKEN`
5. **存儲的 OAuth 憑據** - 來自之前的 `copilot` CLI 登入
6. **GitHub CLI** - `gh auth` 憑據

## 禁用自動登入

要防止 SDK 自動使用存儲的憑據或 `gh` CLI 身份驗證，請使用 `useLoggedInUser: false` 選項：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const client = new CopilotClient({
    useLoggedInUser: false,  // 僅使用明確提供的令牌
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
client = CopilotClient({
    "use_logged_in_user": False,  // 僅使用明確提供的令牌
})
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
client := copilot.NewClient(&copilot.ClientOptions{
    UseLoggedInUser: copilot.Bool(false),  // 僅使用明確提供的令牌
})
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
await using var client = new CopilotClient(new CopilotClientOptions
{
    UseLoggedInUser = false,  // 僅使用明確提供的令牌
});
```

</details>

## 下一步

- [BYOK 文件](./byok_zh_TW.md) - 了解如何使用您自己的 API 金鑰
- [入門指南](../getting-started_zh_TW.md) - 構建您的第一個 Copilot 驅動應用程式
- [MCP 伺服器](../features/mcp_zh_TW.md) - 連接到外部工具
