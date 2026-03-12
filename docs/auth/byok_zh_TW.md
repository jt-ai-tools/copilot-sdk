# 自備金鑰 (Bring Your Own Key, BYOK)

BYOK 允許您在自備模型供應商 API 金鑰的情況下使用 Copilot SDK，從而繞過 GitHub Copilot 身份驗證。這對於企業部署、自定義模型託管或當您希望直接與模型供應商結算時非常有用。

## 支援的供應商

| 供應商 | Type 值 | 備註 |
|----------|------------|-------|
| OpenAI | `"openai"` | OpenAI API 和與 OpenAI 兼容的端點 |
| Azure OpenAI / Azure AI Foundry | `"azure"` | Azure 託管的模型 |
| Anthropic | `"anthropic"` | Claude 模型 |
| Ollama | `"openai"` | 透過與 OpenAI 兼容的 API 使用本地模型 |
| Microsoft Foundry Local | `"openai"` | 透過與 OpenAI 兼容的 API 在您的裝置上本地執行 AI 模型 |
| 其他 OpenAI 兼容端點 | `"openai"` | vLLM, LiteLLM 等 |

## 快速入門：Azure AI Foundry

Azure AI Foundry（前稱 Azure OpenAI）是企業常用的 BYOK 部署目標。以下是一個完整的範例：

<details open>
<summary><strong>Python</strong></summary>

```python
import asyncio
import os
from copilot import CopilotClient

FOUNDRY_MODEL_URL = "https://your-resource.openai.azure.com/openai/v1/"
# 設置 FOUNDRY_API_KEY 環境變數

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-5.2-codex",  # 您的部署名稱
        "provider": {
            "type": "openai",
            "base_url": FOUNDRY_MODEL_URL,
            "wire_api": "responses",  # 舊款模型請使用 "completions"
            "api_key": os.environ["FOUNDRY_API_KEY"],
        },
    })

    done = asyncio.Event()

    def on_event(event):
        if event.type.value == "assistant.message":
            print(event.data.content)
        elif event.type.value == "session.idle":
            done.set()

    session.on(on_event)
    await session.send({"prompt": "2+2 等於多少？"})
    await done.wait()

    await session.disconnect()
    await client.stop()

asyncio.run(main())
```

</details>

<details>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const FOUNDRY_MODEL_URL = "https://your-resource.openai.azure.com/openai/v1/";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-5.2-codex",  // 您的部署名稱
    provider: {
        type: "openai",
        baseUrl: FOUNDRY_MODEL_URL,
        wireApi: "responses",  // 舊款模型請使用 "completions"
        apiKey: process.env.FOUNDRY_API_KEY,
    },
});

session.on("assistant.message", (event) => {
    console.log(event.data.content);
});

await session.sendAndWait({ prompt: "2+2 等於多少？" });
await client.stop();
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
package main

import (
    "context"
    "fmt"
    "os"
    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    ctx := context.Background()
    client := copilot.NewClient(nil)
    if err := client.Start(ctx); err != nil {
        panic(err)
    }
    defer client.Stop()

    session, err := client.CreateSession(ctx, &copilot.SessionConfig{
        Model: "gpt-5.2-codex",  // 您的部署名稱
        Provider: &copilot.ProviderConfig{
            Type:    "openai",
            BaseURL: "https://your-resource.openai.azure.com/openai/v1/",
            WireApi: "responses",  // 舊款模型請使用 "completions"
            APIKey:  os.Getenv("FOUNDRY_API_KEY"),
        },
    })
    if err != nil {
        panic(err)
    }

    response, err := session.SendAndWait(ctx, copilot.MessageOptions{
        Prompt: "2+2 等於多少？",
    })
    if err != nil {
        panic(err)
    }

    fmt.Println(*response.Data.Content)
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5.2-codex",  // 您的部署名稱
    Provider = new ProviderConfig
    {
        Type = "openai",
        BaseUrl = "https://your-resource.openai.azure.com/openai/v1/",
        WireApi = "responses",  // 舊款模型請使用 "completions"
        ApiKey = Environment.GetEnvironmentVariable("FOUNDRY_API_KEY"),
    },
});

var response = await session.SendAndWaitAsync(new MessageOptions
{
    Prompt = "2+2 等於多少？",
});
Console.WriteLine(response?.Data.Content);
```

</details>

## 供應商配置參考 (Provider Configuration Reference)

### ProviderConfig 欄位

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `type` | `"openai"` \| `"azure"` \| `"anthropic"` | 供應商類型 (預設: `"openai"`) |
| `baseUrl` / `base_url` | string | **必填。** API 端點 URL |
| `apiKey` / `api_key` | string | API 金鑰 (對於 Ollama 等本地供應商為選填) |
| `bearerToken` / `bearer_token` | string | Bearer Token 身份驗證 (優先級高於 apiKey) |
| `wireApi` / `wire_api` | `"completions"` \| `"responses"` | API 格式 (預設: `"completions"`) |
| `azure.apiVersion` / `azure.api_version` | string | Azure API 版本 (預設: `"2024-10-21"`) |

### Wire API 格式

`wireApi` 設置決定了使用哪種 OpenAI API 格式：

- **`"completions"`** (預設) - 聊天補全 API (`/chat/completions`)。適用於大多數模型。
- **`"responses"`** - 響應 API。適用於支援新型響應格式的 GPT-5 系列模型。

### 特定類型的注意事項

**OpenAI (`type: "openai"`)**
- 適用於 OpenAI API 和任何與 OpenAI 兼容的端點
- `baseUrl` 應包含完整路徑 (例如 `https://api.openai.com/v1`)

**Azure (`type: "azure"`)**
- 用於原生的 Azure OpenAI 端點
- `baseUrl` 應僅為網址主機部分 (例如 `https://my-resource.openai.azure.com`)
- 請勿在 URL 中包含 `/openai/v1` — SDK 會自行處理路徑構建

**Anthropic (`type: "anthropic"`)**
- 用於直接存取 Anthropic API
- 使用 Claude 特有的 API 格式

## 配置範例 (Example Configurations)

### OpenAI 直接連線

```typescript
provider: {
    type: "openai",
    baseUrl: "https://api.openai.com/v1",
    apiKey: process.env.OPENAI_API_KEY,
}
```

### Azure OpenAI (原生 Azure 端點)

對於位於 `*.openai.azure.com` 的端點，請使用 `type: "azure"`：

```typescript
provider: {
    type: "azure",
    baseUrl: "https://my-resource.openai.azure.com",  // 僅為主機部分
    apiKey: process.env.AZURE_OPENAI_KEY,
    azure: {
        apiVersion: "2024-10-21",
    },
}
```

### Azure AI Foundry (與 OpenAI 兼容的端點)

對於帶有 `/openai/v1/` 端點路徑的 Azure AI Foundry 部署，請使用 `type: "openai"`：

```typescript
provider: {
    type: "openai",
    baseUrl: "https://your-resource.openai.azure.com/openai/v1/",
    apiKey: process.env.FOUNDRY_API_KEY,
    wireApi: "responses",  // 適用於 GPT-5 系列模型
}
```

### Ollama (本地)

```typescript
provider: {
    type: "openai",
    baseUrl: "http://localhost:11434/v1",
    // 本地 Ollama 不需要 apiKey
}
```

### Microsoft Foundry Local

[Microsoft Foundry Local](https://foundrylocal.ai) 讓您能夠透過與 OpenAI 兼容的 API 在自己的裝置上本地執行 AI 模型。請透過 Foundry Local CLI 安裝它，然後將 SDK 指向您的本地端點：

```typescript
provider: {
    type: "openai",
    baseUrl: "http://localhost:<PORT>/v1",
    // 本地 Foundry Local 不需要 apiKey
}
```

> **注意：** Foundry Local 啟動於 **動態連接埠** — 連接埠並非固定。請使用 `foundry service status` 確認服務目前正在監聽的連接埠，然後在 `baseUrl` 中使用該連接埠。

開始使用 Foundry Local：

```bash
# Windows：安裝 Foundry Local CLI (需要 winget)
winget install Microsoft.FoundryLocal

# macOS / Linux：請參閱 https://foundrylocal.ai 獲取安裝說明
# 列出可用模型
foundry model list

# 執行模型 (會自動啟動本地伺服器)
foundry model run phi-4-mini

# 檢查服務執行的連接埠
foundry service status
```

### Anthropic

```typescript
provider: {
    type: "anthropic",
    baseUrl: "https://api.anthropic.com",
    apiKey: process.env.ANTHROPIC_API_KEY,
}
```

### Bearer Token 身份驗證

某些供應商需要使用 Bearer Token 身份驗證而非 API 金鑰：

```typescript
provider: {
    type: "openai",
    baseUrl: "https://my-custom-endpoint.example.com/v1",
    bearerToken: process.env.MY_BEARER_TOKEN,  // 設置 Authorization 標頭
}
```

> **注意：** `bearerToken` 選項僅接受 **靜態令牌字串**。SDK 不會自動刷新此令牌。如果您的令牌過期，請求將失敗，您需要使用新令牌建立新會話。

## 自定義模型列表 (Custom Model Listing)

使用 BYOK 時，CLI 伺服器可能不知道您的供應商支援哪些模型。您可以在用戶端層級提供自定義的 `onListModels` 處理器，以便 `client.listModels()` 以標準的 `ModelInfo` 格式返回您供應商的模型。這讓下游使用者能夠發現可用模型而無需查詢 CLI。

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";
import type { ModelInfo } from "@github/copilot-sdk";

const client = new CopilotClient({
    onListModels: () => [
        {
            id: "my-custom-model",
            name: "My Custom Model",
            capabilities: {
                supports: { vision: false, reasoningEffort: false },
                limits: { max_context_window_tokens: 128000 },
            },
        },
    ],
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient
from copilot.types import ModelInfo, ModelCapabilities, ModelSupports, ModelLimits

client = CopilotClient({
    "on_list_models": lambda: [
        ModelInfo(
            id="my-custom-model",
            name="My Custom Model",
            capabilities=ModelCapabilities(
                supports=ModelSupports(vision=False, reasoning_effort=False),
                limits=ModelLimits(max_context_window_tokens=128000),
            ),
        )
    ],
})
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
package main

import (
    "context"
    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    client := copilot.NewClient(&copilot.ClientOptions{
        OnListModels: func(ctx context.Background) ([]copilot.ModelInfo, error) {
            return []copilot.ModelInfo{
                {
                    ID:   "my-custom-model",
                    Name: "My Custom Model",
                    Capabilities: copilot.ModelCapabilities{
                        Supports: copilot.ModelSupports{Vision: false, ReasoningEffort: false},
                        Limits:   copilot.ModelLimits{MaxContextWindowTokens: 128000},
                    },
                },
            }, nil
        },
    })
    _ = client
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

var client = new CopilotClient(new CopilotClientOptions
{
    OnListModels = (ct) => Task.FromResult(new List<ModelInfo>
    {
        new()
        {
            Id = "my-custom-model",
            Name = "My Custom Model",
            Capabilities = new ModelCapabilities
            {
                Supports = new ModelSupports { Vision = false, ReasoningEffort = false },
                Limits = new ModelLimits { MaxContextWindowTokens = 128000 }
            }
        }
    })
});
```

</details>

結果在第一次調用後會被快取，這與預設行為一致。此處理器會完全取代 CLI 的 `models.list` RPC — 不會回退到伺服器查詢。

## 限制 (Limitations)

使用 BYOK 時，請注意以下限制：

### 身份限制

BYOK 身份驗證僅使用 **靜態憑據**。不支援以下身份供應商：

- ❌ **Microsoft Entra ID (Azure AD)** - 不支援 Entra 受控識別 (Managed Identities) 或服務主體 (Service Principals)
- ❌ **第三方身份供應商** - 不支援 OIDC, SAML 或其他同盟身份 (Federated Identity)
- ❌ **受控識別 (Managed Identities)** - 不支援 Azure 受控識別

您必須使用由您自己管理的 API 金鑰或靜態 Bearer Token。

**為什麼不支援 Entra ID？** 雖然 Entra ID 確實簽發 Bearer Token，但這些令牌壽命較短（通常為 1 小時），且需要透過 Azure Identity SDK 自動刷新。`bearerToken` 選項僅接受靜態字串 — SDK 並沒有回調機制來請求新令牌。對於需要 Entra 身份驗證的長期工作負載，您需要自行實現令牌刷新邏輯，並使用更新後的令牌建立新會話。

### 功能限制

某些 Copilot 功能在 BYOK 模式下可能會有不同的表現：

- **模型可用性** - 僅提供您供應商支援的模型
- **頻率限制 (Rate Limiting)** - 受限於您供應商的頻率限制，而非 Copilot 的
- **使用量追蹤** - 使用量由您的供應商追蹤，而非 GitHub Copilot
- **進階請求 (Premium Requests)** - 不計入 Copilot 進階請求配額

### 供應商特有的限制

| 供應商 | 限制 |
|----------|-------------|
| Azure AI Foundry | 不支援 Entra ID 身份驗證；必須使用 API 金鑰 |
| Ollama | 無 API 金鑰；僅限本地；模型支援程度視情況而定 |
| [Microsoft Foundry Local](https://foundrylocal.ai) | 僅限本地；模型可用性取決於裝置硬體；不需要 API 金鑰 |
| OpenAI | 受限於 OpenAI 的頻率限制與配額 |

## 疑難排解 (Troubleshooting)

### "Model not specified" 錯誤

使用 BYOK 時，`model` 參數是 **必填的**：

```typescript
// ❌ 錯誤：自定義供應商需要指定模型
const session = await client.createSession({
    provider: { type: "openai", baseUrl: "..." },
});

// ✅ 正確：已指定模型
const session = await client.createSession({
    model: "gpt-4",  // 必填！
    provider: { type: "openai", baseUrl: "..." },
});
```

### Azure 端點類型混淆

對於 Azure OpenAI 端點 (`*.openai.azure.com`)，請使用正確的類型：

```typescript
// ❌ 錯誤：對原生 Azure 端點使用 "openai" 類型
provider: {
    type: "openai",  // 這將無法正常運作
    baseUrl: "https://my-resource.openai.azure.com",
}

// ✅ 正確：使用 "azure" 類型
provider: {
    type: "azure",
    baseUrl: "https://my-resource.openai.azure.com",
}
```

但是，如果您的 Azure AI Foundry 部署提供的是與 OpenAI 兼容的端點路徑 (例如 `/openai/v1/`)，請使用 `type: "openai"`：

```typescript
// ✅ 正確：與 OpenAI 兼容的 Azure AI Foundry 端點
provider: {
    type: "openai",
    baseUrl: "https://your-resource.openai.azure.com/openai/v1/",
}
```

### 連線被拒絕 (Ollama)

確保 Ollama 正在執行且可存取：

```bash
# 檢查 Ollama 是否正在執行
curl http://localhost:11434/v1/models

# 如果未執行，啟動 Ollama
ollama serve
```

### 連線被拒絕 (Foundry Local)

Foundry Local 使用動態連接埠，重啟後可能會改變。請確認目前的活動連接埠：

```bash
# 檢查服務狀態和連接埠
foundry service status
```

更新您的 `baseUrl` 以符合輸出中顯示的連接埠。如果服務未執行，請執行一個模型來啟動它：

```bash
foundry model run phi-4-mini
```

### 身份驗證失敗

1. 驗證您的 API 金鑰是否正確且未過期
2. 檢查 `baseUrl` 是否符合您供應商預期的格式
3. 對於 Bearer Token，確保提供了完整的令牌 (不只是前綴)

## 下一步

- [身份驗證概述](./index_zh_TW.md) - 了解所有身份驗證方法
- [入門指南](../getting-started_zh_TW.md) - 構建您的第一個 Copilot 驅動應用程式
