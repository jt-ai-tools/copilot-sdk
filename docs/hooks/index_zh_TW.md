# 工作階段掛鉤 (Session Hooks)

掛鉤 (Hooks) 允許您在對話生命週期的關鍵節點攔截並自定義 Copilot 工作階段的行為。使用掛鉤可以：

- **控制工具執行** - 允許、拒絕或修改工具調用
- **轉換結果** - 在處理工具輸出之前對其進行修改
- **新增內容 (Context)** - 在工作階段開始時注入額外資訊
- **處理錯誤** - 實作自定義錯誤處理
- **稽核與記錄** - 追蹤所有互動以符合規範

## 可用的掛鉤

| 掛鉤 | 觸發條件 | 使用場景 |
|------|---------|----------|
| [`onPreToolUse`](./pre-tool-use_zh_TW.md) | 工具執行前 | 權限控制、參數驗證 |
| [`onPostToolUse`](./post-tool-use_zh_TW.md) | 工具執行後 | 結果轉換、記錄 |
| [`onUserPromptSubmitted`](./user-prompt-submitted_zh_TW.md) | 使用者發送訊息時 | 提示詞修改、過濾 |
| [`onSessionStart`](./session-lifecycle_zh_TW.md#session-start) | 工作階段開始 | 新增內容、配置工作階段 |
| [`onSessionEnd`](./session-lifecycle_zh_TW.md#session-end) | 工作階段結束 | 清理、分析 |
| [`onErrorOccurred`](./error-handling_zh_TW.md) | 發生錯誤時 | 自定義錯誤處理 |

## 快速入門

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      console.log(`調用的工具：${input.toolName}`);
      // 允許所有工具
      return { permissionDecision: "allow" };
    },
    onPostToolUse: async (input) => {
      console.log(`工具結果：${JSON.stringify(input.toolResult)}`);
      return null; // 不進行修改
    },
    onSessionStart: async (input) => {
      return { additionalContext: "使用者偏好簡潔的回答。" };
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient

async def main():
    client = CopilotClient()
    await client.start()

    async def on_pre_tool_use(input_data, invocation):
        print(f"調用的工具：{input_data['toolName']}")
        return {"permissionDecision": "allow"}

    async def on_post_tool_use(input_data, invocation):
        print(f"工具結果：{input_data['toolResult']}")
        return None

    async def on_session_start(input_data, invocation):
        return {"additionalContext": "使用者偏好簡潔的回答。"}

    session = await client.create_session({
        "hooks": {
            "on_pre_tool_use": on_pre_tool_use,
            "on_post_tool_use": on_post_tool_use,
            "on_session_start": on_session_start,
        }
    })
```

</details>

<details>
<summary><strong>Go</strong></summary>

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
        Hooks: &copilot.SessionHooks{
            OnPreToolUse: func(input copilot.PreToolUseHookInput, inv copilot.HookInvocation) (*copilot.PreToolUseHookOutput, error) {
                fmt.Printf("調用的工具：%s\n", input.ToolName)
                return &copilot.PreToolUseHookOutput{
                    PermissionDecision: "allow",
                }, nil
            },
            OnPostToolUse: func(input copilot.PostToolUseHookInput, inv copilot.HookInvocation) (*copilot.PostToolUseHookOutput, error) {
                fmt.Printf("工具結果：%v\n", input.ToolResult)
                return nil, nil
            },
            OnSessionStart: func(input copilot.SessionStartHookInput, inv copilot.HookInvocation) (*copilot.SessionStartHookOutput, error) {
                return &copilot.SessionStartHookOutput{
                    AdditionalContext: "使用者偏好簡潔的回答。",
                }, nil
            },
        },
    })
    _ = session
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

var client = new CopilotClient();

var session = await client.CreateSessionAsync(new SessionConfig
{
    Hooks = new SessionHooks
    {
        OnPreToolUse = (input, invocation) =>
        {
            Console.WriteLine($"調用的工具：{input.ToolName}");
            return Task.FromResult<PreToolUseHookOutput?>(
                new PreToolUseHookOutput { PermissionDecision = "allow" }
            );
        },
        OnPostToolUse = (input, invocation) =>
        {
            Console.WriteLine($"工具結果：{input.ToolResult}");
            return Task.FromResult<PostToolUseHookOutput?>(null);
        },
        OnSessionStart = (input, invocation) =>
        {
            return Task.FromResult<SessionStartHookOutput?>(
                new SessionStartHookOutput { AdditionalContext = "使用者偏好簡潔的回答。" }
            );
        },
    },
});
```

</details>

## 掛鉤調用內容 (Hook Invocation Context)

每個掛鉤都會收到一個 `invocation` 參數，其中包含目前工作階段的內容資訊：

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `sessionId` | string | 目前工作階段的 ID |

這允許掛鉤維護狀態或執行特定於工作階段的邏輯。

## 常見模式

### 記錄所有工具調用

```typescript
const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      console.log(`[${new Date().toISOString()}] 工具：${input.toolName}，參數：${JSON.stringify(input.toolArgs)}`);
      return { permissionDecision: "allow" };
    },
    onPostToolUse: async (input) => {
      console.log(`[${new Date().toISOString()}] 結果：${JSON.stringify(input.toolResult)}`);
      return null;
    },
  },
});
```

### 阻擋危險工具

```typescript
const BLOCKED_TOOLS = ["shell", "bash", "exec"];

const session = await client.createSession({
  hooks: {
    onPreToolUse: async (input) => {
      if (BLOCKED_TOOLS.includes(input.toolName)) {
        return {
          permissionDecision: "deny",
          permissionDecisionReason: "不允許 Shell 存取",
        };
      }
      return { permissionDecision: "allow" };
    },
  },
});
```

### 新增使用者內容 (Context)

```typescript
const session = await client.createSession({
  hooks: {
    onSessionStart: async () => {
      const userPrefs = await loadUserPreferences();
      return {
        additionalContext: `使用者偏好：${JSON.stringify(userPrefs)}`,
      };
    },
  },
});
```

## 掛鉤指南

- **[Pre-Tool Use 掛鉤](./pre-tool-use_zh_TW.md)** - 控制工具執行權限
- **[Post-Tool Use 掛鉤](./post-tool-use_zh_TW.md)** - 轉換工具結果
- **[User Prompt Submitted 掛鉤](./user-prompt-submitted_zh_TW.md)** - 修改使用者提示詞
- **[工作階段生命週期掛鉤](./session-lifecycle_zh_TW.md)** - 工作階段開始與結束
- **[錯誤處理掛鉤](./error-handling_zh_TW.md)** - 自定義錯誤處理

## 延伸閱讀

- [入門指南](../getting-started_zh_TW.md)
- [自定義工具](../getting-started_zh_TW.md#步驟-4-新增自定義工具)
- [偵錯指南](../troubleshooting/debugging_zh_TW.md)
