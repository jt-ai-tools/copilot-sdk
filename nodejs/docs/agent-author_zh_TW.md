# 代理擴充功能編寫指南

為以程式化方式編寫 Copilot CLI 擴充功能的代理提供精確、逐步的參考。

## 工作流

### 步驟 1：建立擴充功能骨架

使用 `extensions_manage` 工具並設定 `operation: "scaffold"`：

```
extensions_manage({ operation: "scaffold", name: "my-extension" })
```

這將建立具備運作骨架的 `.github/extensions/my-extension/extension.mjs`。
對於使用者範圍的擴充功能 (在所有儲存庫中持久存在)，請新增 `location: "user"`。

### 步驟 2：編輯擴充功能檔案

使用 `edit` 或 `create` 工具修改產生的 `extension.mjs`。該檔案必須：
- 命名為 `extension.mjs` (僅支援 `.mjs`)
- 使用 ES 模組語法 (`import`/`export`)
- 呼叫 `joinSession({ ... })`

### 步驟 3：重新載入擴充功能

```
extensions_reload({})
```

這將停止所有執行中的擴充功能，並重新發現/重新啟動它們。新工具會在同一輪次中立即生效 (輪次中重新整理)。

### 步驟 4：驗證

```
extensions_manage({ operation: "list" })
extensions_manage({ operation: "inspect", name: "my-extension" })
```

檢查擴充功能是否已成功載入且未被標記為 "failed"。

---

## 檔案結構

```
.github/extensions/<名稱>/extension.mjs
```

發現規則：
- CLI 會掃描相對於 git 根目錄的 `.github/extensions/`
- 它還會掃描使用者的 copilot 設定擴充功能目錄
- 僅檢查直接子目錄 (不遞迴)
- 每個子目錄必須包含名為 `extension.mjs` 的檔案
- 專案擴充功能在名稱衝突時會覆蓋使用者擴充功能

---

## 最小骨架

```js
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

await joinSession({
    onPermissionRequest: approveAll, // 必填 — 處理權限請求
    tools: [],                     // 選用 — 自訂工具
    hooks: {},                     // 選用 — 生命週期 Hook
});
```

---

## 註冊工具

```js
tools: [
    {
        name: "tool_name",           // 必填。在所有擴充功能中必須是全域唯一的。
        description: "它的功能",      // 必填。在工具描述中顯示給代理。
        parameters: {                // 選用。引數的 JSON 架構。
            type: "object",
            properties: {
                arg1: { type: "string", description: "..." },
            },
            required: ["arg1"],
        },
        handler: async (args, invocation) => {
            // args：符合架構的已解析引數
            // invocation.sessionId：當前工作階段 ID
            // invocation.toolCallId：唯一呼叫 ID
            // invocation.toolName：此工具的名稱
            //
            // 傳回值：字串或 ToolResultObject
            //   字串 → 視為成功
            //   { textResultForLlm, resultType } → 結構化結果
            //     resultType: "success" | "failure" | "rejected" | "denied"
            return `結果：${args.arg1}`;
        },
    },
]
```

**限制：**
- 工具名稱在所有已載入的擴充功能中必須是唯一的。衝突會導致第二個擴充功能載入失敗。
- 處理常式必須傳回字串或 `{ textResultForLlm: string, resultType?: string }`。
- 處理常式接收 `(args, invocation)` —— 第二個引數具有 `sessionId`、`toolCallId`、`toolName`。
- 使用 `session.log()` 將訊息呈現給使用者。不要使用 `console.log()` (stdout 保留給 JSON-RPC)。

---

## 註冊 Hook

```js
hooks: {
    onUserPromptSubmitted: async (input, invocation) => { ... },
    onPreToolUse: async (input, invocation) => { ... },
    onPostToolUse: async (input, invocation) => { ... },
    onSessionStart: async (input, invocation) => { ... },
    onSessionEnd: async (input, invocation) => { ... },
    onErrorOccurred: async (input, invocation) => { ... },
}
```

所有 Hook 輸入都包含 `timestamp` (Unix 毫秒) 和 `cwd` (工作目錄)。
所有處理常式接收 `invocation: { sessionId: string }` 作為第二個引數。
所有處理常式可以傳回 `void`/`undefined` (無操作) 或一個輸出物件。

### onUserPromptSubmitted

**輸入：** `{ prompt: string, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `modifiedPrompt` | `string` | 取代使用者的提示 |
| `additionalContext` | `string` | 作為代理可見的隱藏內容附加 |

### onPreToolUse

**輸入：** `{ toolName: string, toolArgs: unknown, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `permissionDecision` | `"allow" \| "deny" \| "ask"` | 覆蓋權限檢查 |
| `permissionDecisionReason` | `string` | 如果拒絕則顯示給使用者 |
| `modifiedArgs` | `unknown` | 取代工具引數 |
| `additionalContext` | `string` | 注入到對話中 |

### onPostToolUse

**輸入：** `{ toolName: string, toolArgs: unknown, toolResult: ToolResultObject, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `modifiedResult` | `ToolResultObject` | 取代工具結果 |
| `additionalContext` | `string` | 注入到對話中 |

### onSessionStart

**輸入：** `{ source: "startup" \| "resume" \| "new", initialPrompt?: string, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `additionalContext` | `string` | 作為初始內容注入 |

### onSessionEnd

**輸入：** `{ reason: "complete" \| "error" \| "abort" \| "timeout" \| "user_exit", finalMessage?: string, error?: string, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `sessionSummary` | `string` | 工作階段持久化的摘要 |
| `cleanupActions` | `string[]` | 清理描述 |

### onErrorOccurred

**輸入：** `{ error: string, errorContext: "model_call" \| "tool_execution" \| "system" \| "user_input", recoverable: boolean, timestamp, cwd }`

**輸出 (所有欄位均為選用)：**
| 欄位 | 類型 | 效果 |
|-------|------|--------|
| `errorHandling` | `"retry" \| "skip" \| "abort"` | 如何處理錯誤 |
| `retryCount` | `number` | 最大重試次數 (當 errorHandling 為 "retry" 時) |
| `userNotification` | `string` | 顯示給使用者的訊息 |

---

## 工作階段物件

在 `joinSession()` 之後，傳回的 `session` 提供：

### session.send(options)

以程式化方式發送訊息：
```js
await session.send({ prompt: "分析測試結果。" });
await session.send({
    prompt: "審核此檔案",
    attachments: [{ type: "file", path: "./src/index.ts" }],
});
```

### session.sendAndWait(options, timeout?)

發送並封鎖直到代理完成 (在 `session.idle` 時解析)：
```js
const response = await session.sendAndWait({ prompt: "2+2 等於多少？" });
// response?.data.content 包含代理的回覆
```

### session.log(message, options?)

記錄到 CLI 時間軸：
```js
await session.log("擴充功能已就緒");
await session.log("接近速率限制", { level: "warning" });
await session.log("連線失敗", { level: "error" });
await session.log("處理中...", { ephemeral: true }); // 暫時性，不持久化
```

### session.on(eventType, handler)

訂閱工作階段事件。傳回一個取消訂閱函式。
```js
const unsub = session.on("tool.execution_complete", (event) => {
    // event.data.toolName, event.data.success, event.data.result
});
```

### 關鍵事件類型

| 事件 | 關鍵資料欄位 |
|-------|----------------|
| `assistant.message` | `content`, `messageId` |
| `tool.execution_start` | `toolCallId`, `toolName`, `arguments` |
| `tool.execution_complete` | `toolCallId`, `toolName`, `success`, `result`, `error` |
| `user.message` | `content`, `attachments`, `source` |
| `session.idle` | `backgroundTasks` |
| `session.error` | `errorType`, `message`, `stack` |
| `permission.requested` | `requestId`, `permissionRequest.kind` |
| `session.shutdown` | `shutdownType`, `totalPremiumRequests` |

### session.workspacePath

工作階段工作區目錄的路徑 (檢查點、plan.md、檔案/)。如果停用無限工作階段，則為 `undefined`。

### session.rpc

對所有工作階段 API (模型、模式、計畫、工作區等) 的低階類型化 RPC 存取。

---

## 注意事項

- **stdout 保留給 JSON-RPC。** 不要使用 `console.log()` —— 這會損壞協定。使用 `session.log()` 將訊息呈現給使用者。
- **工具名稱衝突是致命的。** 如果兩個擴充功能註冊相同的工具名稱，第二個擴充功能將無法初始化。
- **不要從 `onUserPromptSubmitted` 同步呼叫 `session.send()`。** 使用 `setTimeout(() => session.send(...), 0)` 以避免無限迴圈。
- **擴充功能會在 `/clear` 時重新載入。** 工作階段之間的任何記憶體狀態都會遺失。
- **僅支援 `.mjs`。** 目前尚不支援 TypeScript (`.ts`)。
- **處理常式的傳回值即為工具結果。** 傳回 `undefined` 會發送空的成功。擲回錯誤會發送包含錯誤訊息的失敗。
