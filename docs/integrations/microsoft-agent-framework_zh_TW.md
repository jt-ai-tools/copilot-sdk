# Microsoft Agent Framework 整合

在 [Microsoft Agent Framework](https://devblogs.microsoft.com/semantic-kernel/build-ai-agents-with-github-copilot-sdk-and-microsoft-agent-framework/) (MAF) 中使用 Copilot SDK 作為代理程式提供者 (agent provider)，與 Azure OpenAI、Anthropic 及其他提供者一同建構多代理程式工作流。

## 概覽

Microsoft Agent Framework 是 Semantic Kernel 與 AutoGen 的統一繼承者。它為建構、編排及部署 AI 代理程式提供了標準介面。專用的整合套件讓您可以將 Copilot SDK 用戶端封裝為 MAF 的一等公民代理程式 —— 可與框架中的任何其他代理程式提供者互換使用。

| 概念 | 描述 |
|---------|-------------|
| **Microsoft Agent Framework** | 用於 .NET 與 Python 中單代理程式及多代理程式編排的開源框架 |
| **代理程式提供者 (Agent provider)** | 驅動代理程式的後端 (Copilot、Azure OpenAI、Anthropic 等) |
| **編排器 (Orchestrator)** | 協調代理程式在順序、並行或移交工作流中的 MAF 組件 |
| **A2A 協定** | 框架支援的代理程式間 (Agent-to-Agent) 通訊標準 |

> **注意：** MAF 整合套件適用於 **.NET** 與 **Python**。對於 TypeScript 與 Go，請直接使用 Copilot SDK —— 標準 SDK API 已經提供了工具呼叫、串流與自定義代理程式功能。

## 先決條件

在開始之前，請確保您具備：

- 在您選擇的語言中已建立可運行的 [Copilot SDK 設定](../getting-started_zh_TW.md)
- GitHub Copilot 訂閱 (個人版、商務版或企業版)
- 已安裝 Copilot CLI，或可透過 SDK 隨附的 CLI 使用

## 安裝

安裝 Copilot SDK 以及適用於您語言的 MAF 整合套件：

<details open>
<summary><strong>.NET</strong></summary>

```shell
dotnet add package GitHub.Copilot.SDK
dotnet add package Microsoft.Agents.AI.GitHub.Copilot --prerelease
```

</details>

<details>
<summary><strong>Python</strong></summary>

```shell
pip install copilot-sdk agent-framework-github-copilot
```

</details>

## 基本用法

只需呼叫一個方法，即可將 Copilot SDK 用戶端封裝為 MAF 代理程式。產生的代理程式符合框架的標準介面，可隨處用於需要 MAF 代理程式的場合。

<details open>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->
```csharp
using GitHub.Copilot.SDK;
using Microsoft.Agents.AI;

await using var copilotClient = new CopilotClient();
await copilotClient.StartAsync();

// 封裝為 MAF 代理程式
AIAgent agent = copilotClient.AsAIAgent();

// 使用標準 MAF 介面
string response = await agent.RunAsync("Explain how dependency injection works in ASP.NET Core");
Console.WriteLine(response);
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: skip -->
```python
from agent_framework.github import GitHubCopilotAgent

async def main():
    agent = GitHubCopilotAgent(
        default_options={
            "instructions": "You are a helpful coding assistant.",
        }
    )

    async with agent:
        result = await agent.run("Explain how dependency injection works in FastAPI")
        print(result)
```

</details>

## 新增自定義工具

使用自定義函數工具擴充您的 Copilot 代理程式。透過標準 Copilot SDK 定義的工具，在代理程式於 MAF 中執行時會自動可用。

<details open>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->
```csharp
using GitHub.Copilot.SDK;
using Microsoft.Extensions.AI;
using Microsoft.Agents.AI;

// 定義自定義工具
AIFunction weatherTool = AIFunctionFactory.Create(
    (string location) => $"The weather in {location} is sunny with a high of 25°C.",
    "GetWeather",
    "Get the current weather for a given location."
);

await using var copilotClient = new CopilotClient();
await copilotClient.StartAsync();

// 建立帶有工具的代理程式
AIAgent agent = copilotClient.AsAIAgent(new AIAgentOptions
{
    Tools = new[] { weatherTool },
});

string response = await agent.RunAsync("What's the weather like in Seattle?");
Console.WriteLine(response);
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: skip -->
```python
from agent_framework.github import GitHubCopilotAgent

def get_weather(location: str) -> str:
    """Get the current weather for a given location."""
    return f"The weather in {location} is sunny with a high of 25°C."

async def main():
    agent = GitHubCopilotAgent(
        default_options={
            "instructions": "You are a helpful assistant with access to weather data.",
        },
        tools=[get_weather],
    )

    async with agent:
        result = await agent.run("What's the weather like in Seattle?")
        print(result)
```

</details>

您也可以在 MAF 工具旁使用 Copilot SDK 的原生工具定義：

<details open>
<summary><strong>Node.js / TypeScript (獨立 SDK)</strong></summary>

```typescript
import { CopilotClient, DefineTool } from "@github/copilot-sdk";

const getWeather = DefineTool({
    name: "GetWeather",
    description: "Get the current weather for a given location.",
    parameters: { location: { type: "string", description: "City name" } },
    execute: async ({ location }) => `The weather in ${location} is sunny, 25°C.`,
});

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    tools: [getWeather],
    onPermissionRequest: async () => ({ kind: "approved" }),
});

await session.sendAndWait({ prompt: "What's the weather like in Seattle?" });
```

</details>

## 多代理程式工作流

MAF 整合的主要好處是在編排的工作流中將 Copilot 與其他代理程式提供者結合。使用框架內建的編排器來建立流程，讓不同的代理程式處理不同的步驟。

### 順序工作流 (Sequential Workflow)

依序執行代理程式，將一個代理程式的輸出傳遞給下一個：

<details open>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->
```csharp
using GitHub.Copilot.SDK;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Orchestration;

await using var copilotClient = new CopilotClient();
await copilotClient.StartAsync();

// 用於程式碼審查的 Copilot 代理程式
AIAgent reviewer = copilotClient.AsAIAgent(new AIAgentOptions
{
    Instructions = "You review code for bugs, security issues, and best practices. Be thorough.",
});

// 用於產生文件的 Azure OpenAI 代理程式
AIAgent documentor = AIAgent.FromOpenAI(new OpenAIAgentOptions
{
    Model = "gpt-4.1",
    Instructions = "You write clear, concise documentation for code changes.",
});

// 組合成順序管線
var pipeline = new SequentialOrchestrator(new[] { reviewer, documentor });

string result = await pipeline.RunAsync(
    "Review and document this pull request: added retry logic to the HTTP client"
);
Console.WriteLine(result);
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: skip -->
```python
from agent_framework.github import GitHubCopilotAgent
from agent_framework.openai import OpenAIAgent
from agent_framework.orchestration import SequentialOrchestrator

async def main():
    # 用於程式碼審查的 Copilot 代理程式
    reviewer = GitHubCopilotAgent(
        default_options={
            "instructions": "You review code for bugs, security issues, and best practices.",
        }
    )

    # 用於文件的 OpenAI 代理程式
    documentor = OpenAIAgent(
        model="gpt-4.1",
        instructions="You write clear, concise documentation for code changes.",
    )

    # 組合成順序管線
    pipeline = SequentialOrchestrator(agents=[reviewer, documentor])

    async with pipeline:
        result = await pipeline.run(
            "Review and document this PR: added retry logic to the HTTP client"
        )
        print(result)
```

</details>

### 並行工作流 (Concurrent Workflow)

並行執行多個代理程式並彙總其結果：

<details open>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->
```csharp
using GitHub.Copilot.SDK;
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.Orchestration;

await using var copilotClient = new CopilotClient();
await copilotClient.StartAsync();

AIAgent securityReviewer = copilotClient.AsAIAgent(new AIAgentOptions
{
    Instructions = "Focus exclusively on security vulnerabilities and risks.",
});

AIAgent performanceReviewer = copilotClient.AsAIAgent(new AIAgentOptions
{
    Instructions = "Focus exclusively on performance bottlenecks and optimization opportunities.",
});

// 並行執行兩個審查
var concurrent = new ConcurrentOrchestrator(new[] { securityReviewer, performanceReviewer });

string combinedResult = await concurrent.RunAsync(
    "Analyze this database query module for issues"
);
Console.WriteLine(combinedResult);
```

</details>

## 串流回應

建構互動式應用程式時，串流代理程式回應以顯示即時輸出。MAF 整合保留了 Copilot SDK 的串流能力。

<details open>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->
```csharp
using GitHub.Copilot.SDK;
using Microsoft.Agents.AI;

await using var copilotClient = new CopilotClient();
await copilotClient.StartAsync();

AIAgent agent = copilotClient.AsAIAgent(new AIAgentOptions
{
    Streaming = true,
});

await foreach (var chunk in agent.RunStreamingAsync("Write a quicksort implementation in C#"))
{
    Console.Write(chunk);
}
Console.WriteLine();
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: skip -->
```python
from agent_framework.github import GitHubCopilotAgent

async def main():
    agent = GitHubCopilotAgent(
        default_options={"streaming": True}
    )

    async with agent:
        async for chunk in agent.run_streaming("Write a quicksort in Python"):
            print(chunk, end="", flush=True)
        print()
```

</details>

您也可以不透過 MAF，直接經由 Copilot SDK 進行串流：

<details open>
<summary><strong>Node.js / TypeScript (獨立 SDK)</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
    onPermissionRequest: async () => ({ kind: "approved" }),
});

session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.delta ?? "");
});

await session.sendAndWait({ prompt: "Write a quicksort implementation in TypeScript" });
```

</details>

## 設定參考

### MAF 代理程式選項

| 屬性 | 類型 | 描述 |
|----------|------|-------------|
| `Instructions` / `instructions` | `string` | 代理程式的系統提示詞 (System prompt) |
| `Tools` / `tools` | `AIFunction[]` / `list` | 代理程式可用的自定義函數工具 |
| `Streaming` / `streaming` | `bool` | 啟用串流回應 |
| `Model` / `model` | `string` | 覆寫預設模型 |

### Copilot SDK 選項 (透傳)

建立底層 Copilot 用戶端時，所有標準 [SessionConfig](../getting-started_zh_TW.md) 選項仍然可用。MAF 封裝器在底層會委派給 SDK：

| SDK 功能 | MAF 支援 |
|-------------|-------------|
| 自定義工具 (`DefineTool` / `AIFunctionFactory`) | ✅ 與 MAF 工具合併 |
| MCP 伺服器 | ✅ 在 SDK 用戶端上設定 |
| 自定義代理程式 / 子代理程式 | ✅ 在 Copilot 代理程式中可用 |
| 無限對話 (Infinite sessions) | ✅ 在 SDK 用戶端上設定 |
| 模型選擇 | ✅ 可按代理程式或按次呼叫進行覆寫 |
| 串流 | ✅ 完整支援 delta 事件 |

## 最佳實踐

### 選擇正確的整合層級

當您需要在編排工作流中將 Copilot 與其他提供者結合時，請使用 MAF 封裝器。如果您的應用程式僅使用 Copilot，獨立 SDK 會更簡單且能讓您完全控制：

```typescript
// 獨立 SDK — 完全控制，設定更簡單
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    onPermissionRequest: async () => ({ kind: "approved" }),
});
const response = await session.sendAndWait({ prompt: "Explain this code" });
```

### 保持代理程式專注

建立多代理程式工作流時，給予每個代理程式特定的角色與明確的指示。避免職責重疊：

```typescript
// ❌ 太過模糊 — 角色重疊
const agents = [
    { instructions: "Help with code" },
    { instructions: "Assist with programming" },
];

// ✅ 專注 — 明確的關注點分離
const agents = [
    { instructions: "Review code for security vulnerabilities. Flag SQL injection, XSS, and auth issues." },
    { instructions: "Optimize code performance. Focus on algorithmic complexity and memory usage." },
];
```

### 在編排層級處理錯誤

將代理程式呼叫封裝在錯誤處理中，特別是在多代理程式工作流中，一個代理程式的失敗不應阻塞整個管線：

<!-- docs-validate: skip -->
```csharp
try
{
    string result = await pipeline.RunAsync("Analyze this module");
    Console.WriteLine(result);
}
catch (AgentException ex)
{
    Console.Error.WriteLine($"Agent {ex.AgentName} failed: {ex.Message}");
    // 降級至單代理程式模式或重試
}
```

## 延伸閱讀

- [入門指南](../getting-started_zh_TW.md) — 初始 Copilot SDK 設定
- [自定義代理程式](../features/custom-agents_zh_TW.md) — 在 SDK 中定義專門的子代理程式
- [自定義技能](../features/skills_zh_TW.md) — 可重用的提示詞模組
- [Microsoft Agent Framework 文件](https://learn.microsoft.com/en-us/agent-framework/agents/providers/github-copilot) — Copilot 提供者的官方 MAF 文件
- [部落格：Build AI Agents with GitHub Copilot SDK and Microsoft Agent Framework](https://devblogs.microsoft.com/semantic-kernel/build-ai-agents-with-github-copilot-sdk-and-microsoft-agent-framework/)
