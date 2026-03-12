# MCP 伺服器除錯指南

本指南涵蓋了在使用 Copilot SDK 時，針對 MCP (Model Context Protocol) 伺服器的特定除錯技術。

## 目錄

- [快速診斷](#快速診斷)
- [獨立測試 MCP 伺服器](#獨立測試-mcp-伺服器)
- [常見問題](#常見問題)
- [平台特定問題](#平台特定問題)
- [進階除錯](#進階除錯)

---

## 快速診斷

### 核對清單

在深入研究之前，請驗證以下基本事項：

- [ ] MCP 伺服器執行檔存在且可執行
- [ ] 指令路徑正確 (如有疑慮，請使用絕對路徑)
- [ ] 工具已啟用 (`tools: ["*"]` 或特定的工具名稱)
- [ ] 伺服器正確實作了 MCP 協定 (回應 `initialize`)
- [ ] 沒有防火牆/防毒軟體阻擋該程序 (Windows)

### 啟用 MCP 除錯記錄

在您的 MCP 伺服器設定中新增環境變數：

```typescript
mcpServers: {
  "my-server": {
    type: "local",
    command: "/path/to/server",
    args: [],
    env: {
      MCP_DEBUG: "1",
      DEBUG: "*",
      NODE_DEBUG: "mcp",  // 適用於 Node.js MCP 伺服器
    },
  },
}
```

---

## 獨立測試 MCP 伺服器

務必先在 SDK 之外測試您的 MCP 伺服器。

### 手動協定測試

透過 stdin 發送 `initialize` 請求：

```bash
# Unix/macOS
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | /path/to/your/mcp-server

# Windows (PowerShell)
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | C:\path\to\your\mcp-server.exe
```

**預期回應：**
```json
{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"your-server","version":"1.0"}}}
```

### 測試工具列表

初始化後，請求工具列表：

```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | /path/to/your/mcp-server
```

**預期回應：**
```json
{"jsonrpc":"2.0","id":2,"result":{"tools":[{"name":"my_tool","description":"Does something","inputSchema":{...}}]}}
```

### 互動式測試腳本

建立一個測試腳本來互動式地除錯您的 MCP 伺服器：

```bash
#!/bin/bash
# test-mcp.sh

SERVER="$1"

# 初始化
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

# 發送初始化完成通知
echo '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# 列出工具
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'

# 保持 stdin 開啟
cat
```

用法：
```bash
./test-mcp.sh | /path/to/mcp-server
```

---

## 常見問題

### 伺服器未啟動

**症狀：** 沒有工具出現，記錄中沒有錯誤。

**原因與解決方案：**

| 原因 | 解決方案 |
|-------|----------|
| 指令路徑錯誤 | 使用絕對路徑：`/usr/local/bin/server` |
| 缺少執行權限 | 執行 `chmod +x /path/to/server` |
| 缺少依賴項 | 使用 `ldd` (Linux) 檢查或手動執行 |
| 工作目錄問題 | 在設定中設定 `cwd` |

**透過手動執行進行除錯：**
```bash
# 執行與 SDK 完全相同的指令
cd /expected/working/dir
/path/to/command arg1 arg2
```

### 伺服器已啟動但工具未出現

**症狀：** 伺服器程序正在執行，但沒有可用的工具。

**原因與解決方案：**

1. **設定中未啟用工具：**
   ```typescript
   mcpServers: {
     "server": {
       // ...
       tools: ["*"],  // 必須是 "*" 或工具名稱列表
     },
   }
   ```

2. **伺服器未公開工具：**
   - 手動以 `tools/list` 請求測試
   - 檢查伺服器是否實作了 `tools/list` 方法

3. **初始化握手失敗：**
   - 伺服器必須正確回應 `initialize`
   - 伺服器必須處理 `notifications/initialized`

### 工具已列出但從未被呼叫

**症狀：** 工具出現在除錯記錄中，但模型未使用它們。

**原因與解決方案：**

1. **提示詞不夠明確，不需要工具：**
   ```typescript
   // 太過模糊
   await session.sendAndWait({ prompt: "What's the weather?" });
   
   // 較佳 - 明確提到能力
   await session.sendAndWait({ 
     prompt: "Use the weather tool to get the current temperature in Seattle" 
   });
   ```

2. **工具描述不清晰：**
   ```typescript
   // 不佳 - 模型不知道何時使用它
   { name: "do_thing", description: "Does a thing" }
   
   // 佳 - 目的明確
   { name: "get_weather", description: "Get current weather conditions for a city. Returns temperature, humidity, and conditions." }
   ```

3. **工具 Schema 問題：**
   - 確保 `inputSchema` 是有效的 JSON Schema
   - 必要欄位必須在 `required` 陣列中

### 超時錯誤

**症狀：** `MCP tool call timed out` 錯誤。

**解決方案：**

1. **增加超時時間：**
   ```typescript
   mcpServers: {
     "slow-server": {
       // ...
       timeout: 300000,  // 5 分鐘
     },
   }
   ```

2. **優化伺服器效能：**
   - 新增進度記錄以識別瓶頸
   - 考慮非同步操作
   - 檢查阻塞式 I/O

3. **對於長時間執行的工具**，如果支援，請考慮串流回應。

### JSON-RPC 錯誤

**症狀：** 解析錯誤、無效請求錯誤。

**常見原因：**

1. **伺服器未正確寫入 stdout：**
   - 除錯輸出被送往 stdout 而非 stderr
   - 多餘的換行符或空格
   
   ```typescript
   // 錯誤 - 污染了 stdout
   console.log("Debug info");
   
   // 正確 - 使用 stderr 進行除錯
   console.error("Debug info");
   ```

2. **編碼問題：**
   - 確保使用 UTF-8 編碼
   - 無 BOM (位元組順序標記)

3. **訊息框架 (Framing)：**
   - 每個訊息必須是一個完整的 JSON 物件
   - 以換行符分隔 (每行一個訊息)

---

## 平台特定問題

### Windows

#### .NET 控制台應用程式 / 工具

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public static class McpDotnetConfigExample
{
    public static void Main()
    {
        var servers = new Dictionary<string, McpLocalServerConfig>
        {
            ["my-dotnet-server"] = new McpLocalServerConfig
            {
                Type = "local",
                Command = @"C:\Tools\MyServer\MyServer.exe",
                Args = new List<string>(),
                Cwd = @"C:\Tools\MyServer",
                Tools = new List<string> { "*" },
            },
            ["my-dotnet-tool"] = new McpLocalServerConfig
            {
                Type = "local",
                Command = "dotnet",
                Args = new List<string> { @"C:\Tools\MyTool\MyTool.dll" },
                Cwd = @"C:\Tools\MyTool",
                Tools = new List<string> { "*" },
            }
        };
    }
}
```
<!-- /docs-validate: hidden -->
```csharp
// .NET exe 的正確設定
["my-dotnet-server"] = new McpLocalServerConfig
{
    Type = "local",
    Command = @"C:\Tools\MyServer\MyServer.exe",  // 帶有 .exe 的完整路徑
    Args = new List<string>(),
    Cwd = @"C:\Tools\MyServer",  // 設定工作目錄
    Tools = new List<string> { "*" },
}

// 適用於 dotnet 工具 (DLL)
["my-dotnet-tool"] = new McpLocalServerConfig
{
    Type = "local", 
    Command = "dotnet",
    Args = new List<string> { @"C:\Tools\MyTool\MyTool.dll" },
    Cwd = @"C:\Tools\MyTool",
    Tools = new List<string> { "*" },
}
```

#### NPX 指令

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public static class McpNpxConfigExample
{
    public static void Main()
    {
        var servers = new Dictionary<string, McpLocalServerConfig>
        {
            ["filesystem"] = new McpLocalServerConfig
            {
                Type = "local",
                Command = "cmd",
                Args = new List<string> { "/c", "npx", "-y", "@modelcontextprotocol/server-filesystem", "C:\\allowed\\path" },
                Tools = new List<string> { "*" },
            }
        };
    }
}
```
<!-- /docs-validate: hidden -->
```csharp
// Windows 需要 cmd /c 才能執行 npx
["filesystem"] = new McpLocalServerConfig
{
    Type = "local",
    Command = "cmd",
    Args = new List<string> { "/c", "npx", "-y", "@modelcontextprotocol/server-filesystem", "C:\\allowed\\path" },
    Tools = new List<string> { "*" },
}
```

#### 路徑問題

- 使用原始字串 (`@"C:\path"`) 或正斜線 (`"C:/path"`)
- 盡可能避免在路徑中使用空格
- 如果必須使用空格，請確保正確加引號

#### 防毒軟體/防火牆

Windows Defender 或其他防毒軟體可能會阻擋：
- 新的執行檔
- 透過 stdin/stdout 通訊的程序

**解決方案：** 為您的 MCP 伺服器執行檔新增排除項。

### macOS

#### Gatekeeper 阻擋

```bash
# 如果伺服器被阻擋
xattr -d com.apple.quarantine /path/to/mcp-server
```

#### Homebrew 路徑

<!-- docs-validate: hidden -->
```typescript
import { MCPLocalServerConfig } from "@github/copilot-sdk";

const mcpServers: Record<string, MCPLocalServerConfig> = {
  "my-server": {
    command: "/opt/homebrew/bin/node",
    args: ["/path/to/server.js"],
    tools: ["*"],
  },
};
```
<!-- /docs-validate: hidden -->
```typescript
// GUI 應用程式可能在 PATH 中沒有 /opt/homebrew
mcpServers: {
  "my-server": {
    command: "/opt/homebrew/bin/node",  // 完整路徑
    args: ["/path/to/server.js"],
  },
}
```

### Linux

#### 權限問題

```bash
chmod +x /path/to/mcp-server
```

#### 缺少共享程式庫

```bash
# 檢查依賴項
ldd /path/to/mcp-server

# 安裝缺少的程式庫
apt install libfoo  # Debian/Ubuntu
yum install libfoo  # RHEL/CentOS
```

---

## 進階除錯

### 擷取所有 MCP 流量

建立一個封裝腳本來記錄所有通訊：

```bash
#!/bin/bash
# mcp-debug-wrapper.sh

LOG="/tmp/mcp-debug-$(date +%s).log"
ACTUAL_SERVER="$1"
shift

echo "=== MCP Debug Session ===" >> "$LOG"
echo "Server: $ACTUAL_SERVER" >> "$LOG"
echo "Args: $@" >> "$LOG"
echo "=========================" >> "$LOG"

# 將 stdin/stdout 同時寫入記錄檔
tee -a "$LOG" | "$ACTUAL_SERVER" "$@" 2>> "$LOG" | tee -a "$LOG"
```

使用方式：
```typescript
mcpServers: {
  "debug-server": {
    command: "/path/to/mcp-debug-wrapper.sh",
    args: ["/actual/server/path", "arg1", "arg2"],
  },
}
```

### 使用 MCP Inspector 進行檢視

使用官方的 MCP Inspector 工具：

```bash
npx @modelcontextprotocol/inspector /path/to/your/mcp-server
```

這將提供一個網頁介面來：
- 發送測試請求
- 查看回應
- 檢查工具 Schema

### 協定版本不符

檢查您的伺服器是否支援 SDK 使用的協定版本：

```json
// 在 initialize 回應中，檢查 protocolVersion
{"result":{"protocolVersion":"2024-11-05",...}}
```

如果版本不符，請更新您的 MCP 伺服器程式庫。

---

## 除錯核對清單

在開啟 Issue 或尋求協助時，請收集：

- [ ] SDK 語言與版本
- [ ] CLI 版本 (`copilot --version`)
- [ ] MCP 伺服器類型 (Node.js, Python, .NET, Go 等)
- [ ] 完整的 MCP 伺服器設定 (請遮蔽機密資訊)
- [ ] 手動 `initialize` 測試的結果
- [ ] 手動 `tools/list` 測試的結果  
- [ ] SDK 的除錯記錄
- [ ] 任何錯誤訊息

## 延伸閱讀

- [MCP 概覽](../features/mcp_zh_TW.md) - 設定與安裝
- [一般除錯指南](./debugging_zh_TW.md) - 全 SDK 的除錯
- [MCP 規格](https://modelcontextprotocol.io/) - 官方協定文件
