# Copilot CLI 擴充功能範例

使用 `@github/copilot-sdk` 擴充功能 API 編寫擴充功能的實用指南。

## 擴充功能骨架

每個擴充功能都以相同的樣板開始：

```js
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({
    onPermissionRequest: approveAll,
    hooks: { /* ... */ },
    tools: [ /* ... */ ],
});
```

`joinSession` 傳回一個 `CopilotSession` 物件，您可以使用它發送訊息和訂閱事件。

> **平台注意事項 (Windows vs macOS/Linux)：**
> - 使用 `process.platform === "win32"` 在執行階段偵測 Windows。
> - 剪貼簿：macOS 上使用 `pbcopy`，Windows 上使用 `clip`。
> - 在 Windows 上對於 `.cmd` 指令碼 (如 `code`、`npx`、`npm`) 使用 `exec()` 而非 `execFile()`。
> - PowerShell 標準錯誤重新導向使用 `*>&1` 而非 `2>&1`。

---

## 記錄到時間軸

使用 `session.log()` 將訊息呈現給 CLI 時間軸中的使用者：

```js
const session = await joinSession({
    onPermissionRequest: approveAll,
    hooks: {
        onSessionStart: async () => {
            await session.log("我的擴充功能已載入");
        },
        onPreToolUse: async (input) => {
            if (input.toolName === "bash") {
                await session.log(`執行中：${input.toolArgs?.command}`, { ephemeral: true });
            }
        },
    },
    tools: [],
});
```

層級：`"info"` (預設)、`"warning"`、`"error"`。將 `ephemeral: true` 設定為不持久化的暫時性訊息。

---

## 註冊自訂工具

工具是代理可以呼叫的函式。定義工具時需包含名稱、描述、JSON 架構參數和處理常式。

### 基本工具

```js
tools: [
    {
        name: "my_tool",
        description: "執行一些有用的操作",
        parameters: {
            type: "object",
            properties: {
                input: { type: "string", description: "輸入值" },
            },
            required: ["input"],
        },
        handler: async (args) => {
            return `已處理：${args.input}`;
        },
    },
]
```

### 調用外部 Shell 命令的工具

```js
import { execFile } from "node:child_process";

{
    name: "run_command",
    description: "執行 shell 命令並傳回其輸出",
    parameters: {
        type: "object",
        properties: {
            command: { type: "string", description: "要執行的命令" },
        },
        required: ["command"],
    },
    handler: async (args) => {
        const isWindows = process.platform === "win32";
        const shell = isWindows ? "powershell" : "bash";
        const shellArgs = isWindows
            ? ["-NoProfile", "-Command", args.command]
            : ["-c", args.command];
        return new Promise((resolve) => {
            execFile(shell, shellArgs, (err, stdout, stderr) => {
                if (err) resolve(`錯誤：${stderr || err.message}`);
                else resolve(stdout);
            });
        });
    },
}
```

### 呼叫外部 API 的工具

```js
{
    name: "fetch_data",
    description: "從 API 端點獲取資料",
    parameters: {
        type: "object",
        properties: {
            url: { type: "string", description: "要獲取的 URL" },
        },
        required: ["url"],
    },
    handler: async (args) => {
        const res = await fetch(args.url);
        if (!res.ok) return `錯誤：HTTP ${res.status}`;
        return await res.text();
    },
}
```

### 工具處理常式調用內容

處理常式接收第二個引數，包含調用中繼資料：

```js
handler: async (args, invocation) => {
    // invocation.sessionId  — 當前工作階段 ID
    // invocation.toolCallId — 此工具呼叫的唯一 ID
    // invocation.toolName   — 正在被呼叫的工具名稱
    return "done";
}
```

---

## Hook

Hook 在關鍵的生命週期點攔截並修改行為。在 `hooks` 選項中註冊它們。

### 可用的 Hook

| Hook | 觸發時機 | 可修改項目 |
|------|-----------|------------|
| `onUserPromptSubmitted` | 使用者發送訊息 | 提示文字、新增內容 |
| `onPreToolUse` | 工具執行前 | 工具引數、權限決策、新增內容 |
| `onPostToolUse` | 工具執行後 | 工具結果、新增內容 |
| `onSessionStart` | 工作階段開始或恢復 | 新增內容、修改設定 |
| `onSessionEnd` | 工作階段結束 | 清理操作、摘要 |
| `onErrorOccurred` | 發生錯誤 | 錯誤處理策略 (重試/跳過/中止) |

所有 Hook 輸入都包含 `timestamp` (Unix 毫秒) 和 `cwd` (工作目錄)。

### 修改使用者的訊息

使用 `onUserPromptSubmitted` 在代理看到之前重寫或增強使用者輸入的內容。

```js
hooks: {
    onUserPromptSubmitted: async (input) => {
        // 重寫提示
        return { modifiedPrompt: input.prompt.toUpperCase() };
    },
}
```

### 向每條訊息注入額外內容

傳回 `additionalContext` 以悄悄附加代理將遵循的指令。

```js
hooks: {
    onUserPromptSubmitted: async (input) => {
        return {
            additionalContext: "始終以項目符號回應。遵循我們團隊的編碼標準。",
        };
    },
}
```

### 根據關鍵字發送後續訊息

使用 `session.send()` 以程式化方式注入新的使用者訊息。

```js
hooks: {
    onUserPromptSubmitted: async (input) => {
        if (/\\burgent\\b/i.test(input.prompt)) {
            // 發送後不理的後續訊息
            setTimeout(() => session.send({ prompt: "請優先處理此項。" }), 0);
        }
    },
}
```

> **提示：** 如果您的後續訊息可能再次觸發相同的 Hook，請防止無限迴圈。

### 封鎖危險的工具呼叫

使用 `onPreToolUse` 檢查並選擇性地拒絕工具執行。

```js
hooks: {
    onPreToolUse: async (input) => {
        if (input.toolName === "bash") {
            const cmd = String(input.toolArgs?.command || "");
            if (/rm\\s+-rf/i.test(cmd) || /Remove-Item\\s+.*-Recurse/i.test(cmd)) {
                return {
                    permissionDecision: "deny",
                    permissionDecisionReason: "不允許破壞性命令。",
                };
            }
        }
        // 允許所有其他操作
        return { permissionDecision: "allow" };
    },
}
```

### 在執行前修改工具引數

```js
hooks: {
    onPreToolUse: async (input) => {
        if (input.toolName === "bash") {
            const redirect = process.platform === "win32" ? "*>&1" : "2>&1";
            return {
                modifiedArgs: {
                    ...input.toolArgs,
                    command: `${input.toolArgs.command} ${redirect}`,
                },
            };
        }
    },
}
```

### 當代理建立或編輯檔案時做出反應

使用 `onPostToolUse` 在工具完成後執行副作用。

```js
import { exec } from "node:child_process";

hooks: {
    onPostToolUse: async (input) => {
        if (input.toolName === "create" || input.toolName === "edit") {
            const filePath = input.toolArgs?.path;
            if (filePath) {
                // 在 VS Code 中開啟檔案
                exec(`code "${filePath}"`, () => {});
            }
        }
    },
}
```

### 使用額外內容增強工具結果

```js
hooks: {
    onPostToolUse: async (input) => {
        if (input.toolName === "bash" && input.toolResult?.resultType === "failure") {
            return {
                additionalContext: "命令失敗。嘗試不同的方法。",
            };
        }
    },
}
```

### 在每次檔案編輯後執行 Linter

```js
import { exec } from "node:child_process";

hooks: {
    onPostToolUse: async (input) => {
        if (input.toolName === "edit") {
            const filePath = input.toolArgs?.path;
            if (filePath?.endsWith(".ts")) {
                const result = await new Promise((resolve) => {
                    exec(`npx eslint "${filePath}"`, (err, stdout) => {
                        resolve(err ? stdout : "沒有 Lint 錯誤。");
                    });
                });
                return { additionalContext: `Lint 結果：${result}` };
            }
        }
    },
}
```

### 使用重試邏輯處理錯誤

```js
hooks: {
    onErrorOccurred: async (input) => {
        if (input.recoverable && input.errorContext === "model_call") {
            return { errorHandling: "retry", retryCount: 2 };
        }
        return {
            errorHandling: "abort",
            userNotification: `發生錯誤：${input.error}`,
        };
    },
}
```

### 工作階段生命週期 Hook

```js
hooks: {
    onSessionStart: async (input) => {
        // input.source 是 "startup"、"resume" 或 "new"
        return { additionalContext: "記得為所有變更編寫測試。" };
    },
    onSessionEnd: async (input) => {
        // input.reason 是 "complete"、"error"、"abort"、"timeout" 或 "user_exit"
    },
}
```

---

## 工作階段事件

呼叫 `joinSession` 後，使用 `session.on()` 即時回應事件。

### 接聽特定事件類型

```js
session.on("assistant.message", (event) => {
    // event.data.content 包含代理的回應文字
});
```

### 接聽所有事件

```js
session.on((event) => {
    // event.type 和 event.data 對於所有事件皆可用
});
```

### 取消訂閱事件

`session.on()` 傳回一個取消訂閱函式：

```js
const unsubscribe = session.on("tool.execution_complete", (event) => {
    // event.data.toolName, event.data.success, event.data.result, event.data.error
});

// 稍後停止接聽
unsubscribe();
```

### 範例：自動將代理回應複製到剪貼簿

結合 Hook (偵測關鍵字) 與工作階段事件 (擷取回應)：

```js
import { execFile } from "node:child_process";

let copyNextResponse = false;

function copyToClipboard(text) {
    const cmd = process.platform === "win32" ? "clip" : "pbcopy";
    const proc = execFile(cmd, [], () => {});
    proc.stdin.write(text);
    proc.stdin.end();
}

const session = await joinSession({
    onPermissionRequest: approveAll,
    hooks: {
        onUserPromptSubmitted: async (input) => {
            if (/\\bcopy\\b/i.test(input.prompt)) {
                copyNextResponse = true;
            }
        },
    },
    tools: [],
});

session.on("assistant.message", (event) => {
    if (copyNextResponse) {
        copyNextResponse = false;
        copyToClipboard(event.data.content);
    }
});
```

### 前 10 個最有用的事件類型

| 事件類型 | 描述 | 關鍵資料欄位 |
|-----------|-------------|-----------------|
| `assistant.message` | 代理的最終回應 | `content`, `messageId`, `toolRequests` |
| `assistant.streaming_delta` | 逐個權杖的串流 (暫時) | `totalResponseSizeBytes` |
| `tool.execution_start` | 工具即將執行 | `toolCallId`, `toolName`, `arguments` |
| `tool.execution_complete` | 工具執行完成 | `toolCallId`, `toolName`, `success`, `result`, `error` |
| `user.message` | 使用者發送了訊息 | `content`, `attachments`, `source` |
| `session.idle` | 工作階段完成了一輪處理 | `backgroundTasks` |
| `session.error` | 發生錯誤 | `errorType`, `message`, `stack` |
| `permission.requested` | 代理需要權限 (shell、檔案寫入等) | `requestId`, `permissionRequest.kind` |
| `session.shutdown` | 工作階段結束中 | `shutdownType`, `totalPremiumRequests`, `codeChanges` |
| `assistant.turn_start` | 代理開始新的思考/回應週期 | `turnId` |

### 範例：偵測計書檔案何時被建立或編輯

使用 `session.workspacePath` 定位工作階段的 `plan.md`，然後使用 `fs.watchFile` 偵測變更。
透過 `toolCallId` 關聯 `tool.execution_start` / `tool.execution_complete` 事件，以區分代理編輯與使用者編輯。

```js
import { existsSync, watchFile, readFileSync } from "node:fs";
import { join } from "node:path";
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

const agentEdits = new Set(); // 進行中代理編輯的 toolCallId
const recentAgentPaths = new Set(); // 代理最近寫入的路徑

const session = await joinSession({
    onPermissionRequest: approveAll,
});

const workspace = session.workspacePath; // 例如 ~/.copilot/session-state/<id>
if (workspace) {
    const planPath = join(workspace, "plan.md");
    let lastContent = existsSync(planPath) ? readFileSync(planPath, "utf-8") : null;

    // 追蹤代理編輯以抑制錯誤觸發
    session.on("tool.execution_start", (event) => {
        if ((event.data.toolName === "edit" || event.data.toolName === "create")
            && String(event.data.arguments?.path || "").endsWith("plan.md")) {
            agentEdits.add(event.data.toolCallId);
            recentAgentPaths.add(planPath);
        }
    });
    session.on("tool.execution_complete", (event) => {
        if (agentEdits.delete(event.data.toolCallId)) {
            setTimeout(() => {
                recentAgentPaths.delete(planPath);
                lastContent = existsSync(planPath) ? readFileSync(planPath, "utf-8") : null;
            }, 2000);
        }
    });

    watchFile(planPath, { interval: 1000 }, () => {
        if (recentAgentPaths.has(planPath) || agentEdits.size > 0) return;
        const content = existsSync(planPath) ? readFileSync(planPath, "utf-8") : null;
        if (content === lastContent) return;
        const wasCreated = lastContent === null && content !== null;
        lastContent = content;
        if (content !== null) {
            session.send({
                prompt: `計畫已由使用者${wasCreated ? "建立" : "編輯"}。`,
            });
        }
    });
}
```

### 範例：當使用者手動編輯儲存庫中的任何檔案時做出反應

在 `process.cwd()` 上使用具有 `recursive: true` 的 `fs.watch` 來偵測檔案變更。
透過追蹤 `tool.execution_start` / `tool.execution_complete` 事件來過濾掉代理編輯。

```js
import { watch, readFileSync, statSync } from "node:fs";
import { join, relative, resolve } from "node:path";
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

const agentEditPaths = new Set();

const session = await joinSession({
    onPermissionRequest: approveAll,
});

const cwd = process.cwd();
const IGNORE = new Set(["node_modules", ".git", "dist"]);

// 追蹤代理檔案編輯
session.on("tool.execution_start", (event) => {
    if (event.data.toolName === "edit" || event.data.toolName === "create") {
        const p = String(event.data.arguments?.path || "");
        if (p) agentEditPaths.add(resolve(p));
    }
});
session.on("tool.execution_complete", (event) => {
    // 延遲後清除，避免與 fs.watch 發生競爭
    const p = [...agentEditPaths].find((x) => x); // 任何追蹤的路徑
    setTimeout(() => agentEditPaths.clear(), 3000);
});

const debounce = new Map();

watch(cwd, { recursive: true }, (eventType, filename) => {
    if (!filename || eventType !== "change") return;
    if (filename.split(/[\\\\\\/]/).some((p) => IGNORE.has(p))) return;

    if (debounce.has(filename)) clearTimeout(debounce.get(filename));
    debounce.set(filename, setTimeout(() => {
        debounce.delete(filename);
        const fullPath = join(cwd, filename);
        if (agentEditPaths.has(resolve(fullPath))) return;

        try { if (!statSync(fullPath).isFile()) return; } catch { return; }
        const relPath = relative(cwd, fullPath);
        session.send({
            prompt: `使用者編輯了 \`${relPath}\`。`,
            attachments: [{ type: "file", path: fullPath }],
        });
    }, 500));
});
```

---

## 以程式化方式發送訊息

### 發送後不理

```js
await session.send({ prompt: "分析測試結果。" });
```

### 發送並等待回應

```js
const response = await session.sendAndWait({ prompt: "2 + 2 等於多少？" });
// response?.data.content 包含代理的回覆
```

### 發送具有檔案附件的訊息

```js
await session.send({
    prompt: "審核此檔案",
    attachments: [
        { type: "file", path: "./src/index.ts" },
    ],
});
```

---

## 權限和使用者輸入處理常式

### 自訂權限邏輯

```js
const session = await joinSession({
    onPermissionRequest: async (request) => {
        if (request.kind === "shell") {
            // request.fullCommandText 包含 shell 命令
            return { kind: "approved" };
        }
        if (request.kind === "write") {
            return { kind: "approved" };
        }
        return { kind: "denied-by-rules" };
    },
});
```

### 處理代理問題 (ask_user)

註冊 `onUserInputRequest` 以啟用代理的 `ask_user` 工具：

```js
const session = await joinSession({
    onPermissionRequest: approveAll,
    onUserInputRequest: async (request) => {
        // request.question 包含代理的問題
        // request.choices 包含選項 (如果是多選)
        return { answer: "yes", wasFreeform: false };
    },
});
```

---

## 完整範例：多功能擴充功能

結合工具、Hook 和事件的擴充功能。

```js
import { execFile, exec } from "node:child_process";
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

const isWindows = process.platform === "win32";
let copyNextResponse = false;

function copyToClipboard(text) {
    const proc = execFile(isWindows ? "clip" : "pbcopy", [], () => {});
    proc.stdin.write(text);
    proc.stdin.end();
}

function openInEditor(filePath) {
    if (isWindows) exec(`code "${filePath}"`, () => {});
    else execFile("code", [filePath], () => {});
}

const session = await joinSession({
    onPermissionRequest: approveAll,
    hooks: {
        onUserPromptSubmitted: async (input) => {
            if (/\\bcopy this\\b/i.test(input.prompt)) {
                copyNextResponse = true;
            }
            return {
                additionalContext: "遵循我們團隊的風格指南。使用 4 空格縮排。",
            };
        },
        onPreToolUse: async (input) => {
            if (input.toolName === "bash") {
                const cmd = String(input.toolArgs?.command || "");
                if (/rm\\s+-rf\\s+\\//i.test(cmd) || /Remove-Item\\s+.*-Recurse/i.test(cmd)) {
                    return { permissionDecision: "deny" };
                }
            }
        },
        onPostToolUse: async (input) => {
            if (input.toolName === "create" || input.toolName === "edit") {
                const filePath = input.toolArgs?.path;
                if (filePath) openInEditor(filePath);
            }
        },
    },
    tools: [
        {
            name: "copy_to_clipboard",
            description: "將文字複製到系統剪貼簿。",
            parameters: {
                type: "object",
                properties: {
                    text: { type: "string", description: "要複製的文字" },
                },
                required: ["text"],
            },
            handler: async (args) => {
                return new Promise((resolve) => {
                    const proc = execFile(isWindows ? "clip" : "pbcopy", [], (err) => {
                        if (err) resolve(`錯誤：${err.message}`);
                        else resolve("已複製到剪貼簿。");
                    });
                    proc.stdin.write(args.text);
                    proc.stdin.end();
                });
            },
        },
    ],
});

session.on("assistant.message", (event) => {
    if (copyNextResponse) {
        copyNextResponse = false;
        copyToClipboard(event.data.content);
    }
});

session.on("tool.execution_complete", (event) => {
    // event.data.success, event.data.toolName, event.data.result
});
```
