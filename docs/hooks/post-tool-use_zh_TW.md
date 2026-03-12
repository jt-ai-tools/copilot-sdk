# 工具執行後掛鉤 (Post-Tool Use Hook)

`onPostToolUse` 掛鉤在工具執行**之後**被調用。可用於：

- 轉換或過濾工具結果
- 記錄工具執行情況以供稽核
- 根據結果新增內容 (Context)
- 隱藏對話中的結果

## 掛鉤簽章

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

<!-- docs-validate: hidden -->
```ts
import type { PostToolUseHookInput, HookInvocation, PostToolUseHookOutput } from "@github/copilot-sdk";
type PostToolUseHandler = (
  input: PostToolUseHookInput,
  invocation: HookInvocation
) => Promise<PostToolUseHookOutput | null | undefined>;
```
<!-- /docs-validate: hidden -->
```typescript
type PostToolUseHandler = (
  input: PostToolUseHookInput,
  invocation: HookInvocation
) => Promise<PostToolUseHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import PostToolUseHookInput, HookInvocation, PostToolUseHookOutput
from typing import Callable, Awaitable

PostToolUseHandler = Callable[
    [PostToolUseHookInput, HookInvocation],
    Awaitable[PostToolUseHookOutput | None]
]
```
<!-- /docs-validate: hidden -->
```python
PostToolUseHandler = Callable[
    [PostToolUseHookInput, HookInvocation],
    Awaitable[PostToolUseHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type PostToolUseHandler func(
    input copilot.PostToolUseHookInput,
    invocation copilot.HookInvocation,
) (*copilot.PostToolUseHookOutput, error)

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type PostToolUseHandler func(
    input PostToolUseHookInput,
    invocation HookInvocation,
) (*PostToolUseHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public delegate Task<PostToolUseHookOutput?> PostToolUseHandler(
    PostToolUseHookInput input,
    HookInvocation invocation);
```
<!-- /docs-validate: hidden -->
```csharp
public delegate Task<PostToolUseHookOutput?> PostToolUseHandler(
    PostToolUseHookInput input,
    HookInvocation invocation);
```

</details>

## 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 掛鉤被觸發時的 Unix 時間戳記 |
| `cwd` | string | 目前工作目錄 |
| `toolName` | string | 被調用的工具名稱 |
| `toolArgs` | object | 傳遞給工具的參數 |
| `toolResult` | object | 工具回傳的結果 |

## 輸出 (Output)

回傳 `null` 或 `undefined` 以保持結果不變並通過。否則，回傳一個包含以下任一欄位的物件：

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `modifiedResult` | object | 修改後的結果，將代替原始結果使用 |
| `additionalContext` | string | 注入到對話中的額外內容 (Context) |
| `suppressOutput` | boolean | 如果為 true，結果將不會出現在對話中 |

## 範例

### 記錄所有工具結果

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input, invocation) => {
      console.log(`[${invocation.sessionId}] 工具：${input.toolName}`);
      console.log(`  參數：${JSON.stringify(input.toolArgs)}`);
      console.log(`  結果：${JSON.stringify(input.toolResult)}`);
      return null; // 保持不變並通過
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
async def on_post_tool_use(input_data, invocation):
    print(f"[{invocation['session_id']}] 工具：{input_data['toolName']}")
    print(f"  參數：{input_data['toolArgs']}")
    print(f"  結果：{input_data['toolResult']}")
    return None  # 保持不變並通過

session = await client.create_session({
    "hooks": {"on_post_tool_use": on_post_tool_use}
})
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import (
	"context"
	"fmt"
	copilot "github.com/github/copilot-sdk/go"
)

func main() {
	client := copilot.NewClient(nil)
	session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
		OnPermissionRequest: copilot.PermissionHandler.ApproveAll,
		Hooks: &copilot.SessionHooks{
			OnPostToolUse: func(input copilot.PostToolUseHookInput, inv copilot.HookInvocation) (*copilot.PostToolUseHookOutput, error) {
				fmt.Printf("[%s] 工具：%s\n", inv.SessionID, input.ToolName)
				fmt.Printf("  參數：%v\n", input.ToolArgs)
				fmt.Printf("  結果：%v\n", input.ToolResult)
				return nil, nil
			},
		},
	})
	_ = session
}
```
<!-- /docs-validate: hidden -->
```go
session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Hooks: &copilot.SessionHooks{
        OnPostToolUse: func(input copilot.PostToolUseHookInput, inv copilot.HookInvocation) (*copilot.PostToolUseHookOutput, error) {
            fmt.Printf("[%s] 工具：%s\n", inv.SessionID, input.ToolName)
            fmt.Printf("  參數：%v\n", input.ToolArgs)
            fmt.Printf("  結果：%v\n", input.ToolResult)
            return nil, nil
        },
    },
})
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public static class PostToolUseExample
{
    public static async Task Main()
    {
        await using var client = new CopilotClient();
        var session = await client.CreateSessionAsync(new SessionConfig
        {
            Hooks = new SessionHooks
            {
                OnPostToolUse = (input, invocation) =>
                {
                    Console.WriteLine($"[{invocation.SessionId}] 工具：{input.ToolName}");
                    Console.WriteLine($"  參數：{input.ToolArgs}");
                    Console.WriteLine($"  結果：{input.ToolResult}");
                    return Task.FromResult<PostToolUseHookOutput?>(null);
                },
            },
        });
    }
}
```
<!-- /docs-validate: hidden -->
```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Hooks = new SessionHooks
    {
        OnPostToolUse = (input, invocation) =>
        {
            Console.WriteLine($"[{invocation.SessionId}] 工具：{input.ToolName}");
            Console.WriteLine($"  參數：{input.ToolArgs}");
            Console.WriteLine($"  結果：{input.ToolResult}");
            return Task.FromResult<PostToolUseHookOutput?>(null);
        },
    },
});
```

</details>

### 屏蔽敏感數據

```typescript
const SENSITIVE_PATTERNS = [
  /api[_-]?key["\s:=]+["']?[\w-]+["']?/gi,
  /password["\s:=]+["']?[\w-]+["']?/gi,
  /secret["\s:=]+["']?[\w-]+["']?/gi,
];

const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input) => {
      if (typeof input.toolResult === "string") {
        let redacted = input.toolResult;
        for (const pattern of SENSITIVE_PATTERNS) {
          redacted = redacted.replace(pattern, "[已屏蔽]");
        }
        
        if (redacted !== input.toolResult) {
          return { modifiedResult: redacted };
        }
      }
      return null;
    },
  },
});
```

### 截斷大型結果

```typescript
const MAX_RESULT_LENGTH = 10000;

const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input) => {
      const resultStr = JSON.stringify(input.toolResult);
      
      if (resultStr.length > MAX_RESULT_LENGTH) {
        return {
          modifiedResult: {
            truncated: true,
            originalLength: resultStr.length,
            content: resultStr.substring(0, MAX_RESULT_LENGTH) + "...",
          },
          additionalContext: `註：結果已從 ${resultStr.length} 個字元截斷至 ${MAX_RESULT_LENGTH} 個字元。`,
        };
      }
      return null;
    },
  },
});
```

### 根據結果新增內容 (Context)

```typescript
const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input) => {
      // 如果讀取檔案回傳錯誤，新增有用的提示內容
      if (input.toolName === "read_file" && input.toolResult?.error) {
        return {
          additionalContext: "提示：如果檔案不存在，請考慮建立檔案或檢查路徑是否正確。",
        };
      }
      
      // 如果 shell 指令執行失敗，新增偵錯提示
      if (input.toolName === "shell" && input.toolResult?.exitCode !== 0) {
        return {
          additionalContext: "指令執行失敗。請檢查是否已安裝必要的相依項目。",
        };
      }
      
      return null;
    },
  },
});
```

### 過濾錯誤堆疊追蹤 (Stack Traces)

```typescript
const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input) => {
      if (input.toolResult?.error && input.toolResult?.stack) {
        // 移除內部的堆疊追蹤詳情
        return {
          modifiedResult: {
            error: input.toolResult.error,
            // 僅保留堆疊的前 3 行
            stack: input.toolResult.stack.split("\n").slice(0, 3).join("\n"),
          },
        };
      }
      return null;
    },
  },
});
```

### 用於合規性的稽核軌跡 (Audit Trail)

```typescript
interface AuditEntry {
  timestamp: number;
  sessionId: string;
  toolName: string;
  args: unknown;
  result: unknown;
  success: boolean;
}

const auditLog: AuditEntry[] = [];

const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input, invocation) => {
      auditLog.push({
        timestamp: input.timestamp,
        sessionId: invocation.sessionId,
        toolName: input.toolName,
        args: input.toolArgs,
        result: input.toolResult,
        success: !input.toolResult?.error,
      });
      
      // 可選擇性地持久化到資料庫或檔案
      await saveAuditLog(auditLog);
      
      return null;
    },
  },
});
```

### 隱藏吵雜的結果

```typescript
const NOISY_TOOLS = ["list_directory", "search_codebase"];

const session = await client.createSession({
  hooks: {
    onPostToolUse: async (input) => {
      if (NOISY_TOOLS.includes(input.toolName)) {
        // 總結結果而非顯示完整結果
        const items = Array.isArray(input.toolResult) 
          ? input.toolResult 
          : input.toolResult?.items || [];
        
        return {
          modifiedResult: {
            summary: `找到 ${items.length} 個項目`,
            firstFew: items.slice(0, 5),
          },
        };
      }
      return null;
    },
  },
});
```

## 最佳實踐

1. **不需要變更時回傳 `null`** - 這比回傳空物件或相同的結果更有效率。

2. **謹慎修改結果** - 修改結果可能會影響模型解釋工具輸出的方式。僅在必要時進行修改。

3. **使用 `additionalContext` 提供提示** - 與其修改結果，不如新增內容 (Context) 來幫助模型解釋結果。

4. **記錄時考慮隱私** - 工具結果可能包含敏感數據。在記錄前請進行屏蔽。

5. **保持掛鉤快速執行** - 工具執行後掛鉤是同步執行的。繁重的處理應非同步進行或批次處理。

## 延伸閱讀

- [掛鉤概覽](./index_zh_TW.md)
- [Pre-Tool Use 掛鉤](./pre-tool-use_zh_TW.md)
- [錯誤處理掛鉤](./error-handling_zh_TW.md)
