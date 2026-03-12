# 除錯指南

本指南涵蓋了 Copilot SDK 在所有受支援語言中的常見問題與除錯技術。

## 目錄

- [啟用除錯記錄](#啟用除錯記錄)
- [常見問題](#常見問題)
- [MCP 伺服器除錯](#mcp-伺服器除錯)
- [連線問題](#連線問題)
- [工具執行問題](#工具執行問題)
- [平台特定問題](#平台特定問題)

---

## 啟用除錯記錄

除錯的第一步是啟用詳細記錄，以查看底層發生的情況。

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient({
  logLevel: "debug",  // 選項："none", "error", "warning", "info", "debug", "all"
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient

client = CopilotClient({"log_level": "debug"})
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

func main() {
	client := copilot.NewClient(&copilot.ClientOptions{
		LogLevel: "debug",
	})
	_ = client
}
```
<!-- /docs-validate: hidden -->

```go
import copilot "github.com/github/copilot-sdk/go"

client := copilot.NewClient(&copilot.ClientOptions{
    LogLevel: "debug",
})
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: skip -->

```csharp
using GitHub.Copilot.SDK;
using Microsoft.Extensions.Logging;

// 使用 ILogger
var loggerFactory = LoggerFactory.Create(builder =>
{
    builder.SetMinimumLevel(LogLevel.Debug);
    builder.AddConsole();
});

var client = new CopilotClient(new CopilotClientOptions
{
    LogLevel = "debug",
    Logger = loggerFactory.CreateLogger<CopilotClient>()
});
```

</details>

### 記錄目錄

CLI 會將記錄寫入特定目錄。您可以指定自定義位置：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const client = new CopilotClient({
  cliArgs: ["--log-dir", "/path/to/logs"],
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
# Python SDK 目前不支援傳遞額外的 CLI 參數。
# 記錄會寫入預設位置，或可以在以伺服器模式執行 CLI 時進行設定。
```

> **注意：** Python SDK 的記錄設定較有限。對於進階記錄，請手動執行帶有 `--log-dir` 的 CLI，並透過 `cli_url` 連接。

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

func main() {
	// Go SDK 目前不支援傳遞額外的 CLI 參數。
	// 如需自定義記錄目錄，請手動執行帶有 --log-dir 的 CLI，
	// 並透過 CLIUrl 選項進行連接。
}
```
<!-- /docs-validate: hidden -->

```go
// Go SDK 目前不支援傳遞額外的 CLI 參數。
// 如需自定義記錄目錄，請手動執行帶有 --log-dir 的 CLI，
// 並透過 CLIUrl 選項進行連接。
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
var client = new CopilotClient(new CopilotClientOptions
{
    CliArgs = new[] { "--log-dir", "/path/to/logs" }
});
```

</details>

---

## 常見問題

### "CLI not found" / "copilot: command not found"

**原因：** 未安裝 Copilot CLI，或其不在 PATH 中。

**解決方案：**

1. 安裝 CLI：[安裝指南](https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli)

2. 驗證安裝：
   ```bash
   copilot --version
   ```

3. 或指定完整路徑：

   <details open>
   <summary><strong>Node.js</strong></summary>

   ```typescript
   const client = new CopilotClient({
     cliPath: "/usr/local/bin/copilot",
   });
   ```
   </details>

   <details>
   <summary><strong>Python</strong></summary>

   ```python
   client = CopilotClient({"cli_path": "/usr/local/bin/copilot"})
   ```
   </details>

   <details>
   <summary><strong>Go</strong></summary>

   ```go
   client := copilot.NewClient(&copilot.ClientOptions{
       CLIPath: "/usr/local/bin/copilot",
   })
   ```
   </details>

   <details>
   <summary><strong>.NET</strong></summary>

   ```csharp
   var client = new CopilotClient(new CopilotClientOptions
   {
       CliPath = "/usr/local/bin/copilot"
   });
   ```
   </details>

### "Not authenticated" (未驗證)

**原因：** CLI 未向 GitHub 進行驗證。

**解決方案：**

1. 驗證 CLI：
   ```bash
   copilot auth login
   ```

2. 或以程式化方式提供權杖 (Token)：

   <details open>
   <summary><strong>Node.js</strong></summary>

   ```typescript
   const client = new CopilotClient({
     githubToken: process.env.GITHUB_TOKEN,
   });
   ```
   </details>

   <details>
   <summary><strong>Python</strong></summary>

   ```python
   import os
   client = CopilotClient({"github_token": os.environ.get("GITHUB_TOKEN")})
   ```
   </details>

   <details>
   <summary><strong>Go</strong></summary>

   ```go
   client := copilot.NewClient(&copilot.ClientOptions{
       GithubToken: os.Getenv("GITHUB_TOKEN"),
   })
   ```
   </details>

   <details>
   <summary><strong>.NET</strong></summary>

   ```csharp
   var client = new CopilotClient(new CopilotClientOptions
   {
       GithubToken = Environment.GetEnvironmentVariable("GITHUB_TOKEN")
   });
   ```
   </details>

### "Session not found" (找不到工作階段)

**原因：** 嘗試使用已銷毀或不存在的工作階段。

**解決方案：**

1. 確保在 `disconnect()` 之後不再呼叫方法：
   ```typescript
   await session.disconnect();
   // 之後請勿再使用該 session！
   ```

2. 對於恢復工作階段，請驗證該工作階段 ID 是否存在：
   ```typescript
   const sessions = await client.listSessions();
   console.log("Available sessions:", sessions);
   ```

### "Connection refused" / "ECONNREFUSED" (連線被拒)

**原因：** CLI 伺服器程序崩潰或啟動失敗。

**解決方案：**

1. 檢查 CLI 是否能獨立正常執行：
   ```bash
   copilot --server --stdio
   ```

2. 啟用自動重啟 (預設已啟用)：
   ```typescript
   const client = new CopilotClient({
     autoRestart: true,
   });
   ```

3. 如果使用 TCP 模式，請檢查連接埠衝突：
   ```typescript
   const client = new CopilotClient({
     useStdio: false,
     port: 0,  // 使用隨機可用連接埠
   });
   ```

---

## MCP 伺服器除錯

MCP (Model Context Protocol) 伺服器可能較難除錯。如需完整的 MCP 除錯指引，請參閱專用的 **[MCP 除錯指南](./mcp-debugging_zh_TW.md)**。

### 快速 MCP 核對清單

- [ ] MCP 伺服器執行檔存在且可獨立執行
- [ ] 指令路徑正確 (請使用絕對路徑)
- [ ] 工具已啟用：`tools: ["*"]`
- [ ] 伺服器正確回應 `initialize` 請求
- [ ] 若有需要，已設定工作目錄 (`cwd`)

### 測試您的 MCP 伺服器

在與 SDK 整合之前，請先驗證您的 MCP 伺服器是否正常運作：

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | /path/to/your/mcp-server
```

詳情請參閱 [MCP 除錯指南](./mcp-debugging_zh_TW.md)。

---

## 連線問題

### Stdio vs TCP 模式

SDK 支援兩種傳輸模式：

| 模式 | 描述 | 使用場景 |
|------|-------------|----------|
| **Stdio** (預設) | CLI 作為子程序執行，透過管道 (pipes) 通訊 | 本地開發、單一程序 |
| **TCP** | CLI 獨立執行，透過 TCP 通訊 | 多個用戶端、遠端 CLI |

**Stdio 模式 (預設)：**
```typescript
const client = new CopilotClient({
  useStdio: true,  // 此為預設值
});
```

**TCP 模式：**
```typescript
const client = new CopilotClient({
  useStdio: false,
  port: 8080,  // 或使用 0 以獲取隨機連接埠
});
```

**連接至現有伺服器：**
```typescript
const client = new CopilotClient({
  cliUrl: "localhost:8080",  // 連接至執行中的伺服器
});
```

### 診斷連線失敗

1. **檢查用戶端狀態：**
   ```typescript
   console.log("Connection state:", client.getState());
   // 在 start() 之後應為 "connected"
   ```

2. **監聽狀態變更：**
   ```typescript
   client.on("stateChange", (state) => {
     console.log("State changed to:", state);
   });
   ```

3. **驗證 CLI 程序是否正在執行：**
   ```bash
   # 檢查是否有 copilot 程序
   ps aux | grep copilot
   ```

---

## 工具執行問題

### 自定義工具未被呼叫

1. **驗證工具註冊：**
   ```typescript
   const session = await client.createSession({
     tools: [myTool],
   });
   
   // 檢查已註冊的工具
   console.log("Registered tools:", session.getTools?.());
   ```

2. **檢查工具 Schema 是否為有效的 JSON Schema：**
   ```typescript
   const myTool = {
     name: "get_weather",
     description: "Get weather for a location",
     parameters: {
       type: "object",
       properties: {
         location: { type: "string", description: "City name" },
       },
       required: ["location"],
     },
     handler: async (args) => {
       return { temperature: 72 };
     },
   };
   ```

3. **確保處理器 (handler) 傳回有效的結果：**
   ```typescript
   handler: async (args) => {
     // 必須傳回可序列化為 JSON 的內容
     return { success: true, data: "result" };
     
     // 請勿傳回 undefined 或不可序列化的物件
   }
   ```

### 工具錯誤未顯現

請訂閱錯誤事件：

```typescript
session.on("tool.execution_error", (event) => {
  console.error("Tool error:", event.data);
});

session.on("error", (event) => {
  console.error("Session error:", event.data);
});
```

---

## 平台特定問題

### Windows

1. **路徑分隔符：** 使用原始字串或正斜線：
   ```csharp
   CliPath = @"C:\Program Files\GitHub\copilot.exe"
   // 或
   CliPath = "C:/Program Files/GitHub/copilot.exe"
   ```

2. **PATHEXT 解析：** SDK 會自動處理，但若問題持續：
   ```csharp
   // 明確指定 .exe
   Command = "myserver.exe"  // 而非僅使用 "myserver"
   ```

3. **控制台編碼：** 確保使用 UTF-8 以正確處理 JSON：
   ```csharp
   Console.OutputEncoding = System.Text.Encoding.UTF8;
   ```

### macOS

1. **Gatekeeper 問題：** 若 CLI 被阻擋：
   ```bash
   xattr -d com.apple.quarantine /path/to/copilot
   ```

2. **GUI 應用程式中的 PATH 問題：** GUI 應用程式可能不會繼承外殼 (shell) 的 PATH：
   ```typescript
   const client = new CopilotClient({
     cliPath: "/opt/homebrew/bin/copilot",  // 完整路徑
   });
   ```

### Linux

1. **權限問題：**
   ```bash
   chmod +x /path/to/copilot
   ```

2. **缺少程式庫：** 檢查必要的共享程式庫：
   ```bash
   ldd /path/to/copilot
   ```

---

## 獲取協助

若您仍然遇到困難：

1. **收集除錯資訊：**
   - SDK 版本
   - CLI 版本 (`copilot --version`)
   - 作業系統
   - 除錯記錄
   - 最小化重現程式碼

2. **搜尋現有 Issue：** [GitHub Issues](https://github.com/github/copilot-sdk/issues)

3. **開啟新的 Issue** 並附上收集到的資訊

## 延伸閱讀

- [入門指南](../getting-started_zh_TW.md)
- [MCP 概覽](../features/mcp_zh_TW.md) - MCP 設定與安裝
- [MCP 除錯指南](./mcp-debugging_zh_TW.md) - 詳細的 MCP 疑難排解
- [API 參考資料](https://github.com/github/copilot-sdk)
