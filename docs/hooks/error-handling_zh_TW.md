# 錯誤處理掛鉤 (Error Handling Hook)

`onErrorOccurred` 掛鉤在工作階段執行期間發生錯誤時被調用。可用於：

- 實作自定義錯誤記錄 (logging)
- 追蹤錯誤模式
- 提供使用者友好的錯誤訊息
- 為關鍵錯誤觸發警報

## 掛鉤簽章

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

<!-- docs-validate: hidden -->
```ts
import type { ErrorOccurredHookInput, HookInvocation, ErrorOccurredHookOutput } from "@github/copilot-sdk";
type ErrorOccurredHandler = (
  input: ErrorOccurredHookInput,
  invocation: HookInvocation
) => Promise<ErrorOccurredHookOutput | null | undefined>;
```
<!-- /docs-validate: hidden -->
```typescript
type ErrorOccurredHandler = (
  input: ErrorOccurredHookInput,
  invocation: HookInvocation
) => Promise<ErrorOccurredHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import ErrorOccurredHookInput, HookInvocation, ErrorOccurredHookOutput
from typing import Callable, Awaitable

ErrorOccurredHandler = Callable[
    [ErrorOccurredHookInput, HookInvocation],
    Awaitable[ErrorOccurredHookOutput | None]
]
```
<!-- /docs-validate: hidden -->
```python
ErrorOccurredHandler = Callable[
    [ErrorOccurredHookInput, HookInvocation],
    Awaitable[ErrorOccurredHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type ErrorOccurredHandler func(
    input copilot.ErrorOccurredHookInput,
    invocation copilot.HookInvocation,
) (*copilot.ErrorOccurredHookOutput, error)

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type ErrorOccurredHandler func(
    input ErrorOccurredHookInput,
    invocation HookInvocation,
) (*ErrorOccurredHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public delegate Task<ErrorOccurredHookOutput?> ErrorOccurredHandler(
    ErrorOccurredHookInput input,
    HookInvocation invocation);
```
<!-- /docs-validate: hidden -->
```csharp
public delegate Task<ErrorOccurredHookOutput?> ErrorOccurredHandler(
    ErrorOccurredHookInput input,
    HookInvocation invocation);
```

</details>

## 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 錯誤發生時的 Unix 時間戳記 |
| `cwd` | string | 目前工作目錄 |
| `error` | string | 錯誤訊息 |
| `errorContext` | string | 錯誤發生的地方：`"model_call"`、`"tool_execution"`、`"system"` 或 `"user_input"` |
| `recoverable` | boolean | 錯誤是否有可能被恢復 |

## 輸出 (Output)

回傳 `null` 或 `undefined` 以使用預設錯誤處理。否則，回傳一個包含以下內容的物件：

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `suppressOutput` | boolean | 如果為 true，則不向使用者顯示錯誤輸出 |
| `errorHandling` | string | 如何處理：`"retry"`、`"skip"` 或 `"abort"` |
| `retryCount` | number | 重試次數 (如果 errorHandling 為 `"retry"`) |
| `userNotification` | string | 要向使用者顯示的自定義訊息 |

## 範例

### 基本錯誤記錄

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input, invocation) => {
      console.error(`[${invocation.sessionId}] 錯誤：${input.error}`);
      console.error(`  內容 (Context)：${input.errorContext}`);
      console.error(`  可恢復：${input.recoverable}`);
      return null;
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
async def on_error_occurred(input_data, invocation):
    print(f"[{invocation['session_id']}] 錯誤：{input_data['error']}")
    print(f"  內容 (Context)：{input_data['errorContext']}")
    print(f"  可恢復：{input_data['recoverable']}")
    return None

session = await client.create_session({
    "hooks": {"on_error_occurred": on_error_occurred}
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
			OnErrorOccurred: func(input copilot.ErrorOccurredHookInput, inv copilot.HookInvocation) (*copilot.ErrorOccurredHookOutput, error) {
				fmt.Printf("[%s] 錯誤：%s\n", inv.SessionID, input.Error)
				fmt.Printf("  內容 (Context)：%s\n", input.ErrorContext)
				fmt.Printf("  可恢復：%v\n", input.Recoverable)
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
        OnErrorOccurred: func(input copilot.ErrorOccurredHookInput, inv copilot.HookInvocation) (*copilot.ErrorOccurredHookOutput, error) {
            fmt.Printf("[%s] 錯誤：%s\n", inv.SessionID, input.Error)
            fmt.Printf("  內容 (Context)：%s\n", input.ErrorContext)
            fmt.Printf("  可恢復：%v\n", input.Recoverable)
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

public static class ErrorHandlingExample
{
    public static async Task Main()
    {
        await using var client = new CopilotClient();
        var session = await client.CreateSessionAsync(new SessionConfig
        {
            Hooks = new SessionHooks
            {
                OnErrorOccurred = (input, invocation) =>
                {
                    Console.Error.WriteLine($"[{invocation.SessionId}] 錯誤：{input.Error}");
                    Console.Error.WriteLine($"  內容 (Context)：{input.ErrorContext}");
                    Console.Error.WriteLine($"  可恢復：{input.Recoverable}");
                    return Task.FromResult<ErrorOccurredHookOutput?>(null);
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
        OnErrorOccurred = (input, invocation) =>
        {
            Console.Error.WriteLine($"[{invocation.SessionId}] 錯誤：{input.Error}");
            Console.Error.WriteLine($"  內容 (Context)：{input.ErrorContext}");
            Console.Error.WriteLine($"  可恢復：{input.Recoverable}");
            return Task.FromResult<ErrorOccurredHookOutput?>(null);
        },
    },
});
```

</details>

### 將錯誤發送到監控服務

```typescript
import { captureException } from "@sentry/node"; // 或您的監控服務

const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input, invocation) => {
      captureException(new Error(input.error), {
        tags: {
          sessionId: invocation.sessionId,
          errorContext: input.errorContext,
        },
        extra: {
          error: input.error,
          recoverable: input.recoverable,
          cwd: input.cwd,
        },
      });
      
      return null;
    },
  },
});
```

### 使用者友好的錯誤訊息

```typescript
const ERROR_MESSAGES: Record<string, string> = {
  "model_call": "與 AI 模型通訊時發生問題。請再試一次。",
  "tool_execution": "工具執行失敗。請檢查您的輸入並再試一次。",
  "system": "發生系統錯誤。請稍後再試。",
  "user_input": "您的輸入發生問題。請檢查並再試一次。",
};

const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input) => {
      const friendlyMessage = ERROR_MESSAGES[input.errorContext];
      
      if (friendlyMessage) {
        return {
          userNotification: friendlyMessage,
        };
      }
      
      return null;
    },
  },
});
```

### 隱藏非關鍵錯誤

```typescript
const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input) => {
      // 隱藏可恢復的工具執行錯誤
      if (input.errorContext === "tool_execution" && input.recoverable) {
        console.log(`已隱藏可恢復錯誤：${input.error}`);
        return { suppressOutput: true };
      }
      return null;
    },
  },
});
```

### 加入恢復內容 (Context)

```typescript
const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input) => {
      if (input.errorContext === "tool_execution") {
        return {
          userNotification: `
工具失敗。以下是一些恢復建議：
- 檢查是否已安裝必要的相依項目
- 驗證檔案路徑是否正確
- 嘗試更簡單的方法
          `.trim(),
        };
      }
      
      if (input.errorContext === "model_call" && input.error.includes("rate")) {
        return {
          errorHandling: "retry",
          retryCount: 3,
          userNotification: "達到速率限制。正在重試...",
        };
      }
      
      return null;
    },
  },
});
```

### 追蹤錯誤模式

```typescript
interface ErrorStats {
  count: number;
  lastOccurred: number;
  contexts: string[];
}

const errorStats = new Map<string, ErrorStats>();

const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input, invocation) => {
      const key = `${input.errorContext}:${input.error.substring(0, 50)}`;
      
      const existing = errorStats.get(key) || {
        count: 0,
        lastOccurred: 0,
        contexts: [],
      };
      
      existing.count++;
      existing.lastOccurred = input.timestamp;
      existing.contexts.push(invocation.sessionId);
      
      errorStats.set(key, existing);
      
      // 如果錯誤重複發生，則發出警告
      if (existing.count >= 5) {
        console.warn(`偵測到重複發生的錯誤：${key} (共 ${existing.count} 次)`);
      }
      
      return null;
    },
  },
});
```

### 針對關鍵錯誤發出警報

```typescript
const CRITICAL_CONTEXTS = ["system", "model_call"];

const session = await client.createSession({
  hooks: {
    onErrorOccurred: async (input, invocation) => {
      if (CRITICAL_CONTEXTS.includes(input.errorContext) && !input.recoverable) {
        await sendAlert({
          level: "critical",
          message: `工作階段 ${invocation.sessionId} 中發生關鍵錯誤`,
          error: input.error,
          context: input.errorContext,
          timestamp: new Date(input.timestamp).toISOString(),
        });
      }
      
      return null;
    },
  },
});
```

### 結合其他掛鉤以獲取內容 (Context)

```typescript
const sessionContext = new Map<string, { lastTool?: string; lastPrompt?: string }>();

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input, invocation) => {
      const ctx = sessionContext.get(invocation.sessionId) || {};
      ctx.lastTool = input.toolName;
      sessionContext.set(invocation.sessionId, ctx);
      return { permissionDecision: "allow" };
    },
    
    onUserPromptSubmitted: async (input, invocation) => {
      const ctx = sessionContext.get(invocation.sessionId) || {};
      ctx.lastPrompt = input.prompt.substring(0, 100);
      sessionContext.set(invocation.sessionId, ctx);
      return null;
    },
    
    onErrorOccurred: async (input, invocation) => {
      const ctx = sessionContext.get(invocation.sessionId);
      
      console.error(`工作階段 ${invocation.sessionId} 發生錯誤：`);
      console.error(`  錯誤：${input.error}`);
      console.error(`  內容 (Context)：${input.errorContext}`);
      if (ctx?.lastTool) {
        console.error(`  最後執行的工具：${ctx.lastTool}`);
      }
      if (ctx?.lastPrompt) {
        console.error(`  最後的提示詞：${ctx.lastPrompt}...`);
      }
      
      return null;
    },
  },
});
```

## 最佳實踐

1. **始終記錄錯誤** - 即使您向使用者隱藏了錯誤，也要保留日誌以便進行偵錯。

2. **將錯誤分類** - 使用 `errorType` 來適當地處理不同的錯誤。

3. **不要吞掉關鍵錯誤** - 僅隱藏您確定是非關鍵的錯誤。

4. **保持掛鉤快速執行** - 錯誤處理不應減慢恢復速度。

5. **提供有用的內容 (Context)** - 當錯誤發生時，`additionalContext` 可以幫助模型恢復。

6. **監控錯誤模式** - 追蹤重複發生的錯誤以識別系統性問題。

## 延伸閱讀

- [掛鉤概覽](./index_zh_TW.md)
- [工作階段生命週期掛鉤](./session-lifecycle_zh_TW.md)
- [偵錯指南](../troubleshooting/debugging_zh_TW.md)
