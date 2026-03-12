# 工具使用前鉤子 (Pre-Tool Use Hook)

`onPreToolUse` 鉤子在工具執行**之前**被呼叫。您可以用它來：

- 批准或拒絕工具執行
- 修改工具參數
- 為工具添加上下文
- 在對話中隱藏工具輸出

## 鉤子簽章 (Hook Signature)

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

<!-- docs-validate: hidden -->
```ts
import type { PreToolUseHookInput, HookInvocation, PreToolUseHookOutput } from "@github/copilot-sdk";
type PreToolUseHandler = (
  input: PreToolUseHookInput,
  invocation: HookInvocation
) => Promise<PreToolUseHookOutput | null | undefined>;
```
<!-- /docs-validate: hidden -->
```typescript
type PreToolUseHandler = (
  input: PreToolUseHookInput,
  invocation: HookInvocation
) => Promise<PreToolUseHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import PreToolUseHookInput, HookInvocation, PreToolUseHookOutput
from typing import Callable, Awaitable

PreToolUseHandler = Callable[
    [PreToolUseHookInput, HookInvocation],
    Awaitable[PreToolUseHookOutput | None]
]
```
<!-- /docs-validate: hidden -->
```python
PreToolUseHandler = Callable[
    [PreToolUseHookInput, HookInvocation],
    Awaitable[PreToolUseHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type PreToolUseHandler func(
    input copilot.PreToolUseHookInput,
    invocation copilot.HookInvocation,
) (*copilot.PreToolUseHookOutput, error)

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type PreToolUseHandler func(
    input PreToolUseHookInput,
    invocation HookInvocation,
) (*PreToolUseHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public delegate Task<PreToolUseHookOutput?> PreToolUseHandler(
    PreToolUseHookInput input,
    HookInvocation invocation);
```
<!-- /docs-validate: hidden -->
```csharp
public delegate Task<PreToolUseHookOutput?> PreToolUseHandler(
    PreToolUseHookInput input,
    HookInvocation invocation);
```

</details>

## 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 觸發鉤子時的 Unix 時間戳記 |
| `cwd` | string | 當前工作目錄 |
| `toolName` | string | 正在被呼叫的工具名稱 |
| `toolArgs` | object | 傳遞給工具的參數 |

## 輸出 (Output)

返回 `null` 或 `undefined` 以允許工具在不進行任何更改的情況下執行。否則，返回包含以下任何欄位的對象：

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `permissionDecision` | `"allow"` \| `"deny"` \| `"ask"` | 是否允許工具呼叫 |
| `permissionDecisionReason` | string | 顯示給使用者的說明 (用於 deny/ask) |
| `modifiedArgs` | object | 傳遞給工具的修改後參數 |
| `additionalContext` | string | 注入到對話中的額外上下文 |
| `suppressOutput` | boolean | 如果為 true，工具輸出將不會出現在對話中 |

### 權限決策 (Permission Decisions)

| 決策 | 行為 |
|----------|----------|
| `"allow"` | 工具正常執行 |
| `"deny"` | 工具被阻擋，並向使用者顯示原因 |
| `"ask"` | 提示使用者批准 (互動模式) |

## 範例

### 允許所有工具 (僅記錄)

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input, invocation) => {
      console.log(`[${invocation.sessionId}] 正在呼叫 ${input.toolName}`);
      console.log(`  參數：${JSON.stringify(input.toolArgs)}`);
      return { permissionDecision: "allow" };
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
async def on_pre_tool_use(input_data, invocation):
    print(f"[{invocation['session_id']}] 正在呼叫 {input_data['toolName']}")
    print(f"  參數：{input_data['toolArgs']}")
    return {"permissionDecision": "allow"}

session = await client.create_session({
    "hooks": {"on_pre_tool_use": on_pre_tool_use}
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
			OnPreToolUse: func(input copilot.PreToolUseHookInput, inv copilot.HookInvocation) (*copilot.PreToolUseHookOutput, error) {
				fmt.Printf("[%s] 正在呼叫 %s\n", inv.SessionID, input.ToolName)
				fmt.Printf("  參數：%v\n", input.ToolArgs)
				return &copilot.PreToolUseHookOutput{
					PermissionDecision: "allow",
				}, nil
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
        OnPreToolUse: func(input copilot.PreToolUseHookInput, inv copilot.HookInvocation) (*copilot.PreToolUseHookOutput, error) {
            fmt.Printf("[%s] 正在呼叫 %s\n", inv.SessionID, input.ToolName)
            fmt.Printf("  參數：%v\n", input.ToolArgs)
            return &copilot.PreToolUseHookOutput{
                PermissionDecision: "allow",
            }, nil
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

public static class PreToolUseExample
{
    public static async Task Main()
    {
        await using var client = new CopilotClient();
        var session = await client.CreateSessionAsync(new SessionConfig
        {
            Hooks = new SessionHooks
            {
                OnPreToolUse = (input, invocation) =>
                {
                    Console.WriteLine($"[{invocation.SessionId}] 正在呼叫 {input.ToolName}");
                    Console.WriteLine($"  參數：{input.ToolArgs}");
                    return Task.FromResult<PreToolUseHookOutput?>(
                        new PreToolUseHookOutput { PermissionDecision = "allow" }
                    );
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
        OnPreToolUse = (input, invocation) =>
        {
            Console.WriteLine($"[{invocation.SessionId}] 正在呼叫 {input.ToolName}");
            Console.WriteLine($"  參數：{input.ToolArgs}");
            return Task.FromResult<PreToolUseHookOutput?>(
                new PreToolUseHookOutput { PermissionDecision = "allow" }
            );
        },
    },
});
```

</details>

### 阻擋特定工具

```typescript
const BLOCKED_TOOLS = ["shell", "bash", "write_file", "delete_file"];

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      if (BLOCKED_TOOLS.includes(input.toolName)) {
        return {
          permissionDecision: "deny",
          permissionDecisionReason: `在此環境中不允許使用工具 '${input.toolName}'`,
        };
      }
      return { permissionDecision: "allow" };
    },
  },
});
```

### 修改工具參數

```typescript
const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      // 為所有 shell 命令添加預設超時
      if (input.toolName === "shell" && input.toolArgs) {
        const args = input.toolArgs as { command: string; timeout?: number };
        return {
          permissionDecision: "allow",
          modifiedArgs: {
            ...args,
            timeout: args.timeout ?? 30000, // 預設 30 秒超時
          },
        };
      }
      return { permissionDecision: "allow" };
    },
  },
});
```

### 限制檔案存取特定目錄

```typescript
const ALLOWED_DIRECTORIES = ["/home/user/projects", "/tmp"];

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      if (input.toolName === "read_file" || input.toolName === "write_file") {
        const args = input.toolArgs as { path: string };
        const isAllowed = ALLOWED_DIRECTORIES.some(dir => 
          args.path.startsWith(dir)
        );
        
        if (!isAllowed) {
          return {
            permissionDecision: "deny",
            permissionDecisionReason: `不允許存取 '${args.path}'。允許的目錄：${ALLOWED_DIRECTORIES.join(", ")}`,
          };
        }
      }
      return { permissionDecision: "allow" };
    },
  },
});
```

### 隱藏詳細的工具輸出

```typescript
const VERBOSE_TOOLS = ["list_directory", "search_files"];

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      return {
        permissionDecision: "allow",
        suppressOutput: VERBOSE_TOOLS.includes(input.toolName),
      };
    },
  },
});
```

### 根據工具添加上下文

```typescript
const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      if (input.toolName === "query_database") {
        return {
          permissionDecision: "allow",
          additionalContext: "記住：此資料庫使用 PostgreSQL 語法。請務必使用參數化查詢。",
        };
      }
      return { permissionDecision: "allow" };
    },
  },
});
```

## 最佳實踐

1. **務必返回一個決策** - 返回 `null` 雖然會允許工具執行，但顯式返回 `{ permissionDecision: "allow" }` 會更加清晰。

2. **提供有用的拒絕原因** - 當拒絕執行時，請說明原因以便使用者理解：
   ```typescript
   return {
     permissionDecision: "deny",
     permissionDecisionReason: "Shell 命令需要批准。請描述您想要完成的任務。",
   };
   ```

3. **謹慎修改參數** - 確保修改後的參數仍符合工具預期的架構 (schema)。

4. **考慮效能** - 工具使用前鉤子在每次工具呼叫之前同步運行。請保持其高效。

5. **審慎使用 `suppressOutput`** - 隱藏輸出意味著模型將看不到結果，這可能會影響對話品質。

## 另請參閱

- [鉤子 (Hooks) 概述](./index_zh_TW.md)
- [工具使用後鉤子 (Post-Tool Use Hook)](./post-tool-use_zh_TW.md)
- [偵錯指南](../troubleshooting/debugging_zh_TW.md)
