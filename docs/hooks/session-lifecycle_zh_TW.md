# 工作階段生命週期掛鉤 (Session Lifecycle Hooks)

工作階段生命週期掛鉤讓您可以對工作階段的開始和結束事件做出回應。可用於：

- 在工作階段開始時初始化內容 (Context)
- 在工作階段結束時清理資源
- 追蹤工作階段指標與分析
- 動態配置工作階段行為

## 工作階段開始掛鉤 (Session Start Hook) {#session-start}

`onSessionStart` 掛鉤在工作階段開始（新建或恢復）時被調用。

### 掛鉤簽章

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

<!-- docs-validate: hidden -->
```ts
import type { SessionStartHookInput, HookInvocation, SessionStartHookOutput } from "@github/copilot-sdk";
type SessionStartHandler = (
  input: SessionStartHookInput,
  invocation: HookInvocation
) => Promise<SessionStartHookOutput | null | undefined>;
```
<!-- /docs-validate: hidden -->
```typescript
type SessionStartHandler = (
  input: SessionStartHookInput,
  invocation: HookInvocation
) => Promise<SessionStartHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import SessionStartHookInput, HookInvocation, SessionStartHookOutput
from typing import Callable, Awaitable

SessionStartHandler = Callable[
    [SessionStartHookInput, HookInvocation],
    Awaitable[SessionStartHookOutput | None]
]
```
<!-- /docs-validate: hidden -->
```python
SessionStartHandler = Callable[
    [SessionStartHookInput, HookInvocation],
    Awaitable[SessionStartHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type SessionStartHandler func(
    input copilot.SessionStartHookInput,
    invocation copilot.HookInvocation,
) (*copilot.SessionStartHookOutput, error)

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type SessionStartHandler func(
    input SessionStartHookInput,
    invocation HookInvocation,
) (*SessionStartHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public delegate Task<SessionStartHookOutput?> SessionStartHandler(
    SessionStartHookInput input,
    HookInvocation invocation);
```
<!-- /docs-validate: hidden -->
```csharp
public delegate Task<SessionStartHookOutput?> SessionStartHandler(
    SessionStartHookInput input,
    HookInvocation invocation);
```

</details>

### 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 掛鉤被觸發時的 Unix 時間戳記 |
| `cwd` | string | 目前工作目錄 |
| `source` | `"startup"` \| `"resume"` \| `"new"` | 工作階段的啟動方式 |
| `initialPrompt` | string \| undefined | 初始提示詞 (如果有提供) |

### 輸出 (Output)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `additionalContext` | string | 在工作階段開始時新增的內容 (Context) |
| `modifiedConfig` | object | 覆寫工作階段配置 |

### 範例

#### 在開始時新增專案內容 (Context)

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
  hooks: {
    onSessionStart: async (input, invocation) => {
      console.log(`工作階段 ${invocation.sessionId} 已啟動 (${input.source})`);
      
      const projectInfo = await detectProjectType(input.cwd);
      
      return {
        additionalContext: `
這是一個 ${projectInfo.type} 專案。
主要語言：${projectInfo.language}
套件管理員：${projectInfo.packageManager}
        `.trim(),
      };
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
async def on_session_start(input_data, invocation):
    print(f"工作階段 {invocation['session_id']} 已啟動 ({input_data['source']})")
    
    project_info = await detect_project_type(input_data["cwd"])
    
    return {
        "additionalContext": f"""
這是一個 {project_info['type']} 專案。
主要語言：{project_info['language']}
套件管理員：{project_info['packageManager']}
        """.strip()
    }

session = await client.create_session({
    "hooks": {"on_session_start": on_session_start}
})
```

</details>

#### 處理工作階段恢復 (Resume)

```typescript
const session = await client.createSession({
  hooks: {
    onSessionStart: async (input, invocation) => {
      if (input.source === "resume") {
        // 載入先前的工作階段狀態
        const previousState = await loadSessionState(invocation.sessionId);
        
        return {
          additionalContext: `
工作階段已恢復。先前的內容：
- 最後的主題：${previousState.lastTopic}
- 開啟的檔案：${previousState.openFiles.join(", ")}
          `.trim(),
        };
      }
      return null;
    },
  },
});
```

#### 載入使用者偏好

```typescript
const session = await client.createSession({
  hooks: {
    onSessionStart: async () => {
      const preferences = await loadUserPreferences();
      
      const contextParts = [];
      
      if (preferences.language) {
        contextParts.push(`偏好語言：${preferences.language}`);
      }
      if (preferences.codeStyle) {
        contextParts.push(`程式碼風格：${preferences.codeStyle}`);
      }
      if (preferences.verbosity === "concise") {
        contextParts.push("請保持回應簡潔扼要。");
      }
      
      return {
        additionalContext: contextParts.join("\n"),
      };
    },
  },
});
```

---

## 工作階段結束掛鉤 (Session End Hook) {#session-end}

`onSessionEnd` 掛鉤在工作階段結束時被調用。

### 掛鉤簽章

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
type SessionEndHandler = (
  input: SessionEndHookInput,
  invocation: HookInvocation
) => Promise<SessionEndHookOutput | null | undefined>;
```

</details>

<details>
<summary><strong>Python</strong></summary>

<!-- docs-validate: hidden -->
```python
from copilot.types import SessionEndHookInput, HookInvocation
from typing import Callable, Awaitable

SessionEndHandler = Callable[
    [SessionEndHookInput, HookInvocation],
    Awaitable[None]
]
```
<!-- /docs-validate: hidden -->
```python
SessionEndHandler = Callable[
    [SessionEndHookInput, HookInvocation],
    Awaitable[SessionEndHookOutput | None]
]
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import copilot "github.com/github/copilot-sdk/go"

type SessionEndHandler func(
    input copilot.SessionEndHookInput,
    invocation copilot.HookInvocation,
) error

func main() {}
```
<!-- /docs-validate: hidden -->
```go
type SessionEndHandler func(
    input SessionEndHookInput,
    invocation HookInvocation,
) (*SessionEndHookOutput, error)
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
public delegate Task<SessionEndHookOutput?> SessionEndHandler(
    SessionEndHookInput input,
    HookInvocation invocation);
```

</details>

### 輸入 (Input)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `timestamp` | number | 掛鉤被觸發時的 Unix 時間戳記 |
| `cwd` | string | 目前工作目錄 |
| `reason` | string | 工作階段結束的原因 (見下表) |
| `finalMessage` | string \| undefined | 工作階段的最後一條訊息 |
| `error` | string \| undefined | 如果工作階段因錯誤結束，則為錯誤訊息 |

#### 結束原因 (End Reasons)

| 原因 | 描述 |
|--------|-------------|
| `"complete"` | 工作階段正常完成 |
| `"error"` | 工作階段因錯誤結束 |
| `"abort"` | 工作階段被使用者或程式碼中止 |
| `"timeout"` | 工作階段逾時 |
| `"user_exit"` | 使用者明確結束了工作階段 |

### 輸出 (Output)

| 欄位 | 類型 | 描述 |
|-------|------|-------------|
| `suppressOutput` | boolean | 隱藏最終的工作階段輸出 |
| `cleanupActions` | string[] | 要執行的清理操作列表 |
| `sessionSummary` | string | 用於記錄/分析的工作階段摘要 |

### 範例

#### 追蹤工作階段指標

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const sessionStartTimes = new Map<string, number>();

const session = await client.createSession({
  hooks: {
    onSessionStart: async (input, invocation) => {
      sessionStartTimes.set(invocation.sessionId, input.timestamp);
      return null;
    },
    onSessionEnd: async (input, invocation) => {
      const startTime = sessionStartTimes.get(invocation.sessionId);
      const duration = startTime ? input.timestamp - startTime : 0;
      
      await recordMetrics({
        sessionId: invocation.sessionId,
        duration,
        endReason: input.reason,
      });
      
      sessionStartTimes.delete(invocation.sessionId);
      return null;
    },
  },
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
session_start_times = {}

async def on_session_start(input_data, invocation):
    session_start_times[invocation["session_id"]] = input_data["timestamp"]
    return None

async def on_session_end(input_data, invocation):
    start_time = session_start_times.get(invocation["session_id"])
    duration = input_data["timestamp"] - start_time if start_time else 0
    
    await record_metrics({
        "session_id": invocation["session_id"],
        "duration": duration,
        "end_reason": input_data["reason"],
    })
    
    session_start_times.pop(invocation["session_id"], None)
    return None

session = await client.create_session({
    "hooks": {
        "on_session_start": on_session_start,
        "on_session_end": on_session_end,
    }
})
```

</details>

#### 清理資源

```typescript
const sessionResources = new Map<string, { tempFiles: string[] }>();

const session = await client.createSession({
  hooks: {
    onSessionStart: async (input, invocation) => {
      sessionResources.set(invocation.sessionId, { tempFiles: [] });
      return null;
    },
    onSessionEnd: async (input, invocation) => {
      const resources = sessionResources.get(invocation.sessionId);
      
      if (resources) {
        // 清理暫存檔
        for (const file of resources.tempFiles) {
          await fs.unlink(file).catch(() => {});
        }
        sessionResources.delete(invocation.sessionId);
      }
      
      console.log(`工作階段 ${invocation.sessionId} 已結束：${input.reason}`);
      return null;
    },
  },
});
```

#### 儲存工作階段狀態以供恢復

```typescript
const session = await client.createSession({
  hooks: {
    onSessionEnd: async (input, invocation) => {
      if (input.reason !== "error") {
        // 儲存狀態以供後續恢復
        await saveSessionState(invocation.sessionId, {
          endTime: input.timestamp,
          cwd: input.cwd,
          reason: input.reason,
        });
      }
      return null;
    },
  },
});
```

#### 記錄工作階段摘要

```typescript
const sessionData: Record<string, { prompts: number; tools: number; startTime: number }> = {};

const session = await client.createSession({
  hooks: {
    onSessionStart: async (input, invocation) => {
      sessionData[invocation.sessionId] = { 
        prompts: 0, 
        tools: 0, 
        startTime: input.timestamp 
      };
      return null;
    },
    onUserPromptSubmitted: async (_, invocation) => {
      sessionData[invocation.sessionId].prompts++;
      return null;
    },
    onPreToolUse: async (_, invocation) => {
      sessionData[invocation.sessionId].tools++;
      return { permissionDecision: "allow" };
    },
    onSessionEnd: async (input, invocation) => {
      const data = sessionData[invocation.sessionId];
      console.log(`
工作階段摘要：
  ID：${invocation.sessionId}
  持續時間：${(input.timestamp - data.startTime) / 1000}s
  提示詞數量：${data.prompts}
  工具調用次數：${data.tools}
  結束原因：${input.reason}
      `.trim());
      
      delete sessionData[invocation.sessionId];
      return null;
    },
  },
});
```

## 最佳實踐

1. **保持 `onSessionStart` 快速執行** - 使用者正在等待工作階段就緒。

2. **處理所有結束原因** - 不要假設工作階段總是正常結束；要處理錯誤和中止的情況。

3. **清理資源** - 使用 `onSessionEnd` 來釋放在工作階段期間分配的任何資源。

4. **儲存最少的狀態** - 如果要追蹤工作階段數據，請保持其輕量化。

5. **確保清理操作是等冪的 (Idempotent)** - 如果程序崩潰，`onSessionEnd` 可能不會被調用。

## 延伸閱讀

- [掛鉤概覽](./index_zh_TW.md)
- [錯誤處理掛鉤](./error-handling_zh_TW.md)
- [偵錯指南](../troubleshooting/debugging_zh_TW.md)
