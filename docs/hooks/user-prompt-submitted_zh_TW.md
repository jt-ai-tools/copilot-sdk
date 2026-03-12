# 使用者提示詞提交掛鉤 (User Prompt Submitted Hook)

`onUserPromptSubmitted` 掛鉤在使用者提交訊息時被調用。可用於：

- 修改或增強使用者提示詞
- 在處理前新增內容 (Context)
- 過濾或驗證使用者輸入
- 實作提示詞模板

## 掛鉤簽章

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

<!-- docs-validate: hidden -->
```ts
import type { UserPromptSubmittedHookInput, HookInvocation, UserPromptSubmittedHookOutput } from "@github/copilot-sdk";
type UserPromptSubmittedHandler = (
  input: UserPromptSubmittedHookInput,
  invocation: HookInvocation
) => Promise<UserPromptSubmittedHookOutput | null | undefined>;
```
<!-- /docs-validate: hidden -->
```typescript
type UserPromptSubmittedHandler = (
  input: UserPromptSubmittedHookInput,
  invocation: HookInvocation
) => Promise<UserPromptSubmittedHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import UserPromptSubmittedHookInput, HookInvocation, UserPromptSubmittedHookOutput
from typing import Callable, Awaitable

UserPromptSubmittedHandler = Callable[
    [UserPromptSubmittedHookInput, HookInvocation],
    Awaitable[UserPromptSubmittedHookOutput | None]
]
```
<!-- /docs-validate: hidden -->
```python
UserPromptSubmittedHandler = Callable[
    [UserPromptSubmittedHookInput, HookInvocation],
    Awaitable[UserPromptSubmittedHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type UserPromptSubmittedHandler func(
    input copilot.UserPromptSubmittedHookInput,
    invocation copilot.HookInvocation,
) (*copilot.UserPromptSubmittedHookOutput, error)

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type UserPromptSubmittedHandler func(
    input UserPromptSubmittedHookInput,
    invocation HookInvocation,
) (*UserPromptSubmittedHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public delegate Task<UserPromptSubmittedHookOutput?> UserPromptSubmittedHandler(
    UserPromptSubmittedHookInput input,
    HookInvocation invocation);
```
<!-- /docs-validate: hidden -->
```csharp
public delegate Task<UserPromptSubmittedHookOutput?> UserPromptSubmittedHandler(
    UserPromptSubmittedHookInput input,
    HookInvocation invocation);
```

</details>

## 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 掛鉤被觸發時的 Unix 時間戳記 |
| `cwd` | string | 目前工作目錄 |
| `prompt` | string | 使用者提交的提示詞 |

## 輸出 (Output)

回傳 `null` 或 `undefined` 以保持提示詞不變。否則，回傳一個包含以下任一欄位的物件：

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `modifiedPrompt` | string | 修改後的提示詞，將代替原始提示詞使用 |
| `additionalContext` | string | 新增到對話中的額外內容 (Context) |
| `suppressOutput` | boolean | 如果為 true，則隱藏助理的回應輸出 |

## 範例

### 記錄所有使用者提示詞

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input, invocation) => {
      console.log(`[${invocation.sessionId}] 使用者：${input.prompt}`);
      return null; // 保持不變並通過
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
async def on_user_prompt_submitted(input_data, invocation):
    print(f"[{invocation['session_id']}] 使用者：{input_data['prompt']}")
    return None

session = await client.create_session({
    "hooks": {"on_user_prompt_submitted": on_user_prompt_submitted}
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
			OnUserPromptSubmitted: func(input copilot.UserPromptSubmittedHookInput, inv copilot.HookInvocation) (*copilot.UserPromptSubmittedHookOutput, error) {
				fmt.Printf("[%s] 使用者：%s\n", inv.SessionID, input.Prompt)
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
        OnUserPromptSubmitted: func(input copilot.UserPromptSubmittedHookInput, inv copilot.HookInvocation) (*copilot.UserPromptSubmittedHookOutput, error) {
            fmt.Printf("[%s] 使用者：%s\n", inv.SessionID, input.Prompt)
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

public static class UserPromptSubmittedExample
{
    public static async Task Main()
    {
        await using var client = new CopilotClient();
        var session = await client.CreateSessionAsync(new SessionConfig
        {
            Hooks = new SessionHooks
            {
                OnUserPromptSubmitted = (input, invocation) =>
                {
                    Console.WriteLine($"[{invocation.SessionId}] 使用者：{input.Prompt}");
                    return Task.FromResult<UserPromptSubmittedHookOutput?>(null);
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
        OnUserPromptSubmitted = (input, invocation) =>
        {
            Console.WriteLine($"[{invocation.SessionId}] 使用者：{input.Prompt}");
            return Task.FromResult<UserPromptSubmittedHookOutput?>(null);
        },
    },
});
```

</details>

### 新增專案內容 (Context)

```typescript
const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      const projectInfo = await getProjectInfo();
      
      return {
        additionalContext: `
專案：${projectInfo.name}
語言：${projectInfo.language}
框架：${projectInfo.framework}
        `.trim(),
      };
    },
  },
});
```

### 展開簡寫指令

```typescript
const SHORTCUTS: Record<string, string> = {
  "/fix": "請修正程式碼中的錯誤",
  "/explain": "請詳細解釋這段程式碼",
  "/test": "請為這段程式碼撰寫單元測試",
  "/refactor": "請重構這段程式碼以提高可讀性和可維護性",
};

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      for (const [shortcut, expansion] of Object.entries(SHORTCUTS)) {
        if (input.prompt.startsWith(shortcut)) {
          const rest = input.prompt.slice(shortcut.length).trim();
          return {
            modifiedPrompt: `${expansion}${rest ? `：${rest}` : ""}`,
          };
        }
      }
      return null;
    },
  },
});
```

### 內容過濾

```typescript
const BLOCKED_PATTERNS = [
  /password\s*[:=]/i,
  /api[_-]?key\s*[:=]/i,
  /secret\s*[:=]/i,
];

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      for (const pattern of BLOCKED_PATTERNS) {
        if (pattern.test(input.prompt)) {
          // 將提示詞替換為警告訊息
          return {
            modifiedPrompt: "[內容已封鎖：請勿在提示詞中包含敏感憑證。請改用環境變數。]",
            suppressOutput: true,
          };
        }
      }
      return null;
    },
  },
});
```

### 強制執行提示詞長度限制

```typescript
const MAX_PROMPT_LENGTH = 10000;

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      if (input.prompt.length > MAX_PROMPT_LENGTH) {
        // 截斷提示詞並新增內容
        return {
          modifiedPrompt: input.prompt.substring(0, MAX_PROMPT_LENGTH),
          additionalContext: `註：原始提示詞長度為 ${input.prompt.length} 個字元，已截斷至 ${MAX_PROMPT_LENGTH} 個字元。`,
        };
      }
      return null;
    },
  },
});
```

### 新增使用者偏好

```typescript
interface UserPreferences {
  codeStyle: "concise" | "verbose";
  preferredLanguage: string;
  experienceLevel: "beginner" | "intermediate" | "expert";
}

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      const prefs: UserPreferences = await loadUserPreferences();
      
      const contextParts = [];
      
      if (prefs.codeStyle === "concise") {
        contextParts.push("使用者偏好簡潔且註釋最少的程式碼。");
      } else {
        contextParts.push("使用者偏好詳細且帶有註釋的程式碼。");
      }
      
      if (prefs.experienceLevel === "beginner") {
        contextParts.push("請用簡單的術語解釋概念。");
      }
      
      return {
        additionalContext: contextParts.join(" "),
      };
    },
  },
});
```

### 速率限制 (Rate Limiting)

```typescript
const promptTimestamps: number[] = [];
const RATE_LIMIT = 10; // 提示詞數量
const RATE_WINDOW = 60000; // 1 分鐘

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      const now = Date.now();
      
      // 移除時間窗外的時間戳記
      while (promptTimestamps.length > 0 && promptTimestamps[0] < now - RATE_WINDOW) {
        promptTimestamps.shift();
      }
      
      if (promptTimestamps.length >= RATE_LIMIT) {
        return {
          reject: true,
          rejectReason: `已超過速率限制。請稍候再發送更多提示詞。`,
        };
      }
      
      promptTimestamps.push(now);
      return null;
    },
  },
});
```

### 提示詞模板

```typescript
const TEMPLATES: Record<string, (args: string) => string> = {
  "bug:": (desc) => `我發現了一個 bug：${desc}

請幫我：
1. 理解為什麼會發生這種情況
2. 建議修正方法
3. 解釋如何防止類似的 bug`,

  "feature:": (desc) => `我想實作這個功能：${desc}

請：
1. 概述實作方法
2. 識別潛在挑戰
3. 提供範例程式碼`,
};

const session = await client.createSession({
  hooks: {
    onUserPromptSubmitted: async (input) => {
      for (const [prefix, template] of Object.entries(TEMPLATES)) {
        if (input.prompt.toLowerCase().startsWith(prefix)) {
          const args = input.prompt.slice(prefix.length).trim();
          return {
            modifiedPrompt: template(args),
          };
        }
      }
      return null;
    },
  },
});
```

## 最佳實踐

1. **保留使用者意圖** - 修改提示詞時，確保核心意圖保持清晰。

2. **對修改保持透明** - 如果您大幅更改了提示詞，請考慮記錄或通知使用者。

3. **優先使用 `additionalContext` 而非 `modifiedPrompt`** - 新增內容比重寫提示詞的侵入性較小。

4. **提供清晰的拒絕理由** - 拒絕提示詞時，解釋原因以及如何修正。

5. **保持快速處理** - 此掛鉤在每條使用者訊息上都會執行。避免耗時的操作。

## 延伸閱讀

- [掛鉤概覽](./index_zh_TW.md)
- [工作階段生命週期掛鉤](./session-lifecycle_zh_TW.md)
- [Pre-Tool Use 掛鉤](./pre-tool-use_zh_TW.md)
