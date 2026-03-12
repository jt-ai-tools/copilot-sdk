# 在 GitHub Copilot SDK 中使用 MCP 伺服器

Copilot SDK 可以與 **MCP 伺服器** (Model Context Protocol，模型上下文協定) 整合，透過外部工具擴展助手的技能。MCP 伺服器作為獨立程序運行，並公開 Copilot 在對話期間可以呼叫的工具 (函式)。

> **注意：** 這是一個不斷發展的功能。有關正在進行的討論，請參閱 [issue #36](https://github.com/github/copilot-sdk/issues/36)。

## 什麼是 MCP？

[模型上下文協定 (MCP)](https://modelcontextprotocol.io/) 是一個用於將 AI 助手連接到外部工具和資料來源的開放標準。MCP 伺服器可以：

- 執行程式碼或腳本
- 查詢資料庫
- 存取檔案系統
- 呼叫外部 API
- 以及更多功能

## 伺服器類型

SDK 支援兩種類型的 MCP 伺服器：

| 類型 | 描述 | 使用場景 |
|------|-------------|----------|
| **本地/Stdio (Local/Stdio)** | 作為子程序運行，透過 stdin/stdout 通訊 | 本地工具、檔案存取、自定義腳本 |
| **HTTP/SSE** | 透過 HTTP 存取的遠端伺服器 | 共享服務、雲端託管工具 |

## 配置

### Node.js / TypeScript

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-5",
    mcpServers: {
        // 本地 MCP 伺服器 (stdio)
        "my-local-server": {
            type: "local",
            command: "node",
            args: ["./mcp-server.js"],
            env: { DEBUG: "true" },
            cwd: "./servers",
            tools: ["*"],  // "*" = 所有工具, [] = 無, 或列出特定工具
            timeout: 30000,
        },
        // 遠端 MCP 伺服器 (HTTP)
        "github": {
            type: "http",
            url: "https://api.githubcopilot.com/mcp/",
            headers: { "Authorization": "Bearer ${TOKEN}" },
            tools: ["*"],
        },
    },
});
```

### Python

```python
import asyncio
from copilot import CopilotClient

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-5",
        "mcp_servers": {
            # 本地 MCP 伺服器 (stdio)
            "my-local-server": {
                "type": "local",
                "command": "python",
                "args": ["./mcp_server.py"],
                "env": {"DEBUG": "true"},
                "cwd": "./servers",
                "tools": ["*"],
                "timeout": 30000,
            },
            # 遠端 MCP 伺服器 (HTTP)
            "github": {
                "type": "http",
                "url": "https://api.githubcopilot.com/mcp/",
                "headers": {"Authorization": "Bearer ${TOKEN}"},
                "tools": ["*"],
            },
        },
    })

    response = await session.send_and_wait({
        "prompt": "列出我最近的 GitHub 通知"
    })
    print(response.data.content)

    await client.stop()

asyncio.run(main())
```

### Go

```go
package main

import (
    "context"
    "log"
    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    ctx := context.Background()
    client := copilot.NewClient(nil)
    if err := client.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer client.Stop()

    // MCPServerConfig 是一個 map[string]any，具有靈活性
    session, err := client.CreateSession(ctx, &copilot.SessionConfig{
        Model: "gpt-5",
        MCPServers: map[string]copilot.MCPServerConfig{
            "my-local-server": {
                "type":    "local",
                "command": "node",
                "args":    []string{"./mcp-server.js"},
                "tools":   []string{"*"},
            },
        },
    })
    if err != nil {
        log.Fatal(err)
    }
    defer session.Disconnect()

    // 使用工作階段...
}
```

### .NET

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    McpServers = new Dictionary<string, object>
    {
        ["my-local-server"] = new McpLocalServerConfig
        {
            Type = "local",
            Command = "node",
            Args = new List<string> { "./mcp-server.js" },
            Tools = new List<string> { "*" },
        },
    },
});
```

## 快速入門：檔案系統 MCP 伺服器

這是一個使用官方 [`@modelcontextprotocol/server-filesystem`](https://www.npmjs.com/package/@modelcontextprotocol/server-filesystem) MCP 伺服器的完整範例：

```typescript
import { CopilotClient } from "@github/copilot-sdk";

async function main() {
    const client = new CopilotClient();

    // 建立帶有檔案系統 MCP 伺服器的工作階段
    const session = await client.createSession({
        mcpServers: {
            filesystem: {
                type: "local",
                command: "npx",
                args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
                tools: ["*"],
            },
        },
    });

    console.log("工作階段已建立：", session.sessionId);

    // 模型現在可以使用檔案系統工具
    const result = await session.sendAndWait({
        prompt: "列出允許目錄中的檔案",
    });

    console.log("回應：", result?.data?.content);

    await session.disconnect();
    await client.stop();
}

main();
```

**輸出：**
```
工作階段已建立：18b3482b-bcba-40ba-9f02-ad2ac949a59a
回應：允許的目錄是 `/tmp`，其中包含各種檔案和子目錄，
包括臨時系統檔案、日誌檔案以及不同應用程式的目錄。
```

> **提示：** 您可以使用來自 [MCP 伺服器目錄](https://github.com/modelcontextprotocol/servers) 的任何 MCP 伺服器。熱門選項包括 `@modelcontextprotocol/server-github`、`@modelcontextprotocol/server-sqlite` 和 `@modelcontextprotocol/server-puppeteer`。

## 配置選項

### 本地/Stdio 伺服器

| 屬性 | 類型 | 是否必需 | 描述 |
|----------|------|----------|-------------|
| `type` | `"local"` 或 `"stdio"` | 否 | 伺服器類型 (預設為 local) |
| `command` | `string` | 是 | 要執行的命令 |
| `args` | `string[]` | 是 | 命令參數 |
| `env` | `object` | 否 | 環境變數 |
| `cwd` | `string` | 否 | 工作目錄 |
| `tools` | `string[]` | 否 | 要啟用的工具 (`["*"]` 代表全部，`[]` 代表不啟用) |
| `timeout` | `number` | 否 | 超時時間 (以毫秒為單位) |

### 遠端伺服器 (HTTP/SSE)

| 屬性 | 類型 | 是否必需 | 描述 |
|----------|------|----------|-------------|
| `type` | `"http"` 或 `"sse"` | 是 | 伺服器類型 |
| `url` | `string` | 是 | 伺服器 URL |
| `headers` | `object` | 否 | HTTP 標頭 (例如用於身份驗證) |
| `tools` | `string[]` | 否 | 要啟用的工具 |
| `timeout` | `number` | 否 | 超時時間 (以毫秒為單位) |

## 疑難排解

### 工具未顯示或未被呼叫

1. **驗證 MCP 伺服器是否正確啟動**
   - 檢查命令和參數是否正確
   - 確保伺服器程序在啟動時不會崩潰
   - 檢查 stderr 中的錯誤輸出

2. **檢查工具配置**
   - 確保 `tools` 設定為 `["*"]` 或列出了您需要的特定工具
   - 空陣列 `[]` 表示未啟用任何工具

3. **驗證遠端伺服器的連線性**
   - 確保 URL 可存取
   - 檢查身份驗證標頭是否正確

### 常見問題

| 問題 | 解決方案 |
|-------|----------|
| 「找不到 MCP 伺服器 (MCP server not found)」 | 驗證命令路徑是否正確且可執行 |
| 「連線被拒絕 (Connection refused)」(HTTP) | 檢查 URL 並確保伺服器正在運行 |
| 「超時 (Timeout)」錯誤 | 增加 `timeout` 值或檢查伺服器效能 |
| 工具正常運作但未被呼叫 | 確保您的提示明確需要該工具的功能 |

有關詳細的偵錯指引，請參閱 **[MCP 偵錯指南](../troubleshooting/mcp-debugging_zh_TW.md)**。

## 相關資源

- [模型上下文協定規範 (Model Context Protocol Specification)](https://modelcontextprotocol.io/)
- [MCP 伺服器目錄 (MCP Servers Directory)](https://github.com/modelcontextprotocol/servers) - 社群 MCP 伺服器
- [GitHub MCP 伺服器](https://github.com/github/github-mcp-server) - 官方 GitHub MCP 伺服器
- [入門指南](../getting-started_zh_TW.md) - SDK 基礎知識和自定義工具
- [通用偵錯指南](../troubleshooting/mcp-debugging_zh_TW.md) - SDK 範圍內的偵錯

## 另請參閱

- [MCP 偵錯指南](../troubleshooting/mcp-debugging_zh_TW.md) - 詳細的 MCP 疑難排解
- [Issue #9](https://github.com/github/copilot-sdk/issues/9) - 原始 MCP 工具使用問題
- [Issue #36](https://github.com/github/copilot-sdk/issues/36) - MCP 文件追蹤問題
