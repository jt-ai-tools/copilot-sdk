# 適用於 Node.js/TypeScript 的 Copilot SDK

用於透過 JSON-RPC 以程式化方式控制 GitHub Copilot CLI 的 TypeScript SDK。

> **注意：** 此 SDK 處於技術預覽階段，可能會發生破壞性變更。

## 安裝

```bash
npm install @github/copilot-sdk
```

## 執行範例

嘗試互動式聊天範例 (從儲存庫根目錄)：

```bash
cd nodejs
npm ci
npm run build
cd samples
npm install
npm start
```

## 快速入門

```typescript
import { CopilotClient } from "@github/copilot-sdk";

// 建立並啟動用戶端
const client = new CopilotClient();
await client.start();

// 建立一個工作階段
const session = await client.createSession({
    model: "gpt-5",
});

// 使用定型事件處理常式等待回應
const done = new Promise<void>((resolve) => {
    session.on("assistant.message", (event) => {
        console.log(event.data.content);
    });
    session.on("session.idle", () => {
        resolve();
    });
});

// 發送訊息並等待完成
await session.send({ prompt: "2+2 等於多少？" });
await done;

// 清理
await session.disconnect();
await client.stop();
```

工作階段還支援 `Symbol.asyncDispose`，以便與 [`await using`](https://github.com/tc39/proposal-explicit-resource-management) (TypeScript 5.2+/Node.js 18.0+) 一起使用：

```typescript
await using session = await client.createSession({ model: "gpt-5" });
// 離開範圍時，工作階段會自動中斷連接
```

## API 參考

### CopilotClient

#### 建構函式

```typescript
new CopilotClient(options?: CopilotClientOptions)
```

**選項：**

- `cliPath?: string` - CLI 執行檔路徑 (預設：來自 PATH 的 "copilot")
- `cliArgs?: string[]` - 在 SDK 管理的旗標之前附加的額外引數 (例如，使用 `node` 時為 `["./dist-cli/index.js"]`)
- `cliUrl?: string` - 要連接的現有 CLI 伺服器 URL (例如，`"localhost:8080"`、`"http://127.0.0.1:9000"` 或僅為 `"8080"`)。提供後，用戶端將不會衍生 CLI 程序。
- `port?: number` - 伺服器連接埠 (預設：0 表示隨機)
- `useStdio?: boolean` - 使用 stdio 傳輸而非 TCP (預設：true)
- `logLevel?: string` - 記錄層級 (預設："info")
- `autoStart?: boolean` - 自動啟動伺服器 (預設：true)
- `autoRestart?: boolean` - 當機時自動重新啟動 (預設：true)
- `githubToken?: string` - 用於身分驗證的 GitHub 權杖。提供後，優先於其他驗證方法。
- `useLoggedInUser?: boolean` - 是否使用已登入使用者進行身分驗證 (預設：true，但提供 `githubToken` 時為 false)。不能與 `cliUrl` 一起使用。

#### 方法

##### `start(): Promise<void>`

啟動 CLI 伺服器並建立連接。

##### `stop(): Promise<Error[]>`

停止伺服器並關閉所有工作階段。傳回清理過程中遇到的任何錯誤列表。

##### `forceStop(): Promise<void>`

強制停止 CLI 伺服器而不進行正常清理。當 `stop()` 花費太長時間時使用。

##### `createSession(config?: SessionConfig): Promise<CopilotSession>`

建立一個新的對話工作階段。

**設定：**

- `sessionId?: string` - 自訂工作階段 ID。
- `model?: string` - 要使用的模型 ("gpt-5"、"claude-sonnet-4.5" 等)。**使用自訂提供者時為必填。**
- `reasoningEffort?: "low" | "medium" | "high" | "xhigh"` - 支援模型的推理努力層級。使用 `listModels()` 檢查哪些模型支援此選項。
- `tools?: Tool[]` - 公開給 CLI 的自訂工具
- `systemMessage?: SystemMessageConfig` - 系統訊息自訂 (見下文)
- `infiniteSessions?: InfiniteSessionConfig` - 設定自動內容壓縮 (見下文)
- `provider?: ProviderConfig` - 自訂 API 提供者設定 (BYOK - 自備金鑰)。請參閱 [自訂提供者](#custom-providers) 章節。
- `onUserInputRequest?: UserInputHandler` - 來自代理的使用者輸入請求處理常式。啟用 `ask_user` 工具。請參閱 [使用者輸入請求](#user-input-requests) 章節。
- `hooks?: SessionHooks` - 工作階段生命週期事件的 Hook 處理常式。請參閱 [工作階段 Hook](#session-hooks) 章節。

##### `resumeSession(sessionId: string, config?: ResumeSessionConfig): Promise<CopilotSession>`

恢復現有工作階段。如果啟用了無限工作階段，則傳回已填寫 `workspacePath` 的工作階段。

##### `ping(message?: string): Promise<{ message: string; timestamp: number }>`

偵測伺服器以檢查連線。

##### `getState(): ConnectionState`

獲取當前連線狀態。

##### `listSessions(filter?: SessionListFilter): Promise<SessionMetadata[]>`

列出所有可用的工作階段。可選擇依工作目錄內容進行篩選。

**SessionMetadata:**

- `sessionId: string` - 唯一的工作階段識別碼
- `startTime: Date` - 工作階段建立時間
- `modifiedTime: Date` - 工作階段最後修改時間
- `summary?: string` - 選用的工作階段摘要
- `isRemote: boolean` - 工作階段是否為遠端
- `context?: SessionContext` - 工作階段建立時的工作目錄內容

**SessionContext:**

- `cwd: string` - 建立工作階段的工作目錄
- `gitRoot?: string` - Git 儲存庫根目錄 (如果在 git 儲存庫中)
- `repository?: string` - "擁有者/儲存庫" 格式的 GitHub 儲存庫
- `branch?: string` - 當前 git 分支

##### `deleteSession(sessionId: string): Promise<void>`

從磁碟刪除工作階段及其資料。

##### `getForegroundSessionId(): Promise<string | undefined>`

獲取當前在 TUI 中顯示的工作階段 ID。僅在連接到以 TUI+伺服器模式 (`--ui-server`) 執行的伺服器時可用。

##### `setForegroundSessionId(sessionId: string): Promise<void>`

請求 TUI 切換到顯示指定的工作階段。僅在 TUI+伺服器模式下可用。

##### `on(eventType: SessionLifecycleEventType, handler): () => void`

訂閱特定的工作階段生命週期事件類型。傳回一個取消訂閱函式。

```typescript
const unsubscribe = client.on("session.foreground", (event) => {
    console.log(`工作階段 ${event.sessionId} 現在處於前景`);
});
```

##### `on(handler: SessionLifecycleHandler): () => void`

訂閱所有工作階段生命週期事件。傳回一個取消訂閱函式。

```typescript
const unsubscribe = client.on((event) => {
    console.log(`${event.type}: ${event.sessionId}`);
});
```

**生命週期事件類型：**
- `session.created` - 建立了一個新的工作階段
- `session.deleted` - 刪除了一個工作階段
- `session.updated` - 更新了一個工作階段 (例如，有新訊息)
- `session.foreground` - 工作階段成為 TUI 中的前景工作階段
- `session.background` - 工作階段不再是前景工作階段

---

### CopilotSession

代表單個對話工作階段。

#### 屬性

##### `sessionId: string`

此工作階段的唯一識別碼。

##### `workspacePath?: string`

啟用無限工作階段時的工作階段工作區目錄路徑。包含 `checkpoints/`、`plan.md` 和 `files/` 子目錄。如果停用無限工作階段，則為 undefined。

#### 方法

##### `send(options: MessageOptions): Promise<string>`

向工作階段發送訊息。訊息加入佇列後立即傳回；使用事件處理常式或 `sendAndWait()` 等待完成。

**選項：**

- `prompt: string` - 要發送的訊息/提示
- `attachments?: Array<{type, path, displayName}>` - 檔案附件
- `mode?: "enqueue" | "immediate"` - 傳送模式

傳回訊息 ID。

##### `sendAndWait(options: MessageOptions, timeout?: number): Promise<AssistantMessageEvent | undefined>`

發送訊息並等待直到工作階段變為閒置狀態。

**選項：**

- `prompt: string` - 要發送的訊息/提示
- `attachments?: Array<{type, path, displayName}>` - 檔案附件
- `mode?: "enqueue" | "immediate"` - 傳送模式
- `timeout?: number` - 選用的逾時時間 (以毫秒為單位)

傳回最終的助理訊息事件，如果未收到則為 undefined。

##### `on(eventType: string, handler: TypedSessionEventHandler): () => void`

訂閱特定的事件類型。處理常式接收正確類型的事件。

```typescript
// 透過完整的類型推斷接聽特定的事件類型
session.on("assistant.message", (event) => {
    console.log(event.data.content); // TypeScript 知道 event.data.content
});

session.on("session.idle", () => {
    console.log("工作階段已閒置");
});

// 接聽串流事件
session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});
```

##### `on(handler: SessionEventHandler): () => void`

訂閱所有工作階段事件。傳回一個取消訂閱函式。

```typescript
const unsubscribe = session.on((event) => {
    // 處理任何事件類型
    console.log(event.type, event);
});

// 稍後...
unsubscribe();
```

##### `abort(): Promise<void>`

中止此工作階段中目前正在處理的訊息。

##### `getMessages(): Promise<SessionEvent[]>`

獲取此工作階段的所有事件/訊息。

##### `disconnect(): Promise<void>`

中斷工作階段連接並釋放資源。磁碟上的工作階段資料將保留以便稍後恢復。

##### `destroy(): Promise<void>` *(已棄用)*

已棄用 —— 請改用 `disconnect()`。

---

## 事件類型

工作階段在處理期間會發出各種事件：

- `user.message` - 新增了使用者訊息
- `assistant.message` - 助理回應
- `assistant.message_delta` - 串流回應區塊
- `tool.execution_start` - 工具執行開始
- `tool.execution_complete` - 工具執行完成
- 以及更多...

有關完整詳細資訊，請參閱原始碼中的 `SessionEvent` 類型。

## 影像支援

SDK 透過 `attachments` 參數支援影像附件。您可以透過提供影像檔案路徑來附加影像：

```typescript
await session.send({
    prompt: "這張影像中是什麼？",
    attachments: [
        {
            type: "file",
            path: "/path/to/image.jpg",
        },
    ],
});
```

支援的影像格式包括 JPG、PNG、GIF 和其他常見影像類型。代理的 `view` 工具也可以直接從檔案系統讀取影像，因此您也可以提出如下問題：

```typescript
await session.send({ prompt: "此目錄中最近的 jpg 描繪了什麼？" });
```

## 串流 (Streaming)

啟用串流以在產生助理回應區塊時接收它們：

```typescript
const session = await client.createSession({
    model: "gpt-5",
    streaming: true,
});

// 使用定型事件處理常式等待完成
const done = new Promise<void>((resolve) => {
    session.on("assistant.message_delta", (event) => {
        // 串流訊息區塊 - 增量列印
        process.stdout.write(event.data.deltaContent);
    });

    session.on("assistant.reasoning_delta", (event) => {
        // 串流推理區塊 (如果模型支援推理)
        process.stdout.write(event.data.deltaContent);
    });

    session.on("assistant.message", (event) => {
        // 最終訊息 - 完整內容
        console.log("\n--- 最終訊息 ---");
        console.log(event.data.content);
    });

    session.on("assistant.reasoning", (event) => {
        // 最終推理內容 (如果模型支援推理)
        console.log("--- 推理 ---");
        console.log(event.data.content);
    });

    session.on("session.idle", () => {
        // 工作階段處理完成
        resolve();
    });
});

await session.send({ prompt: "給我講個短篇故事" });
await done; // 等待串流完成
```

當 `streaming: true` 時：

- 發送 `assistant.message_delta` 事件，其中 `deltaContent` 包含增量文字
- 發送 `assistant.reasoning_delta` 事件，其中 `deltaContent` 用於推理/思維鏈 (取決於模型)
- 累加 `deltaContent` 值以逐步建立完整回應
- 無論串流設定如何，始終會發送最終的 `assistant.message` 和 `assistant.reasoning` 事件

注意：`assistant.message` 和 `assistant.reasoning` (最終事件) 無論串流設定為何都會發送。

## 進階用法

### 手動伺服器控制

```typescript
const client = new CopilotClient({ autoStart: false });

// 手動啟動
await client.start();

// 使用用戶端...

// 手動停止
await client.stop();
```

### 工具

當模型需要您擁有的功能時，您可以讓 CLI 回呼您的程序。使用具有 Zod 架構的 `defineTool` 進行類型安全的工具定義：

```ts
import { z } from "zod";
import { CopilotClient, defineTool } from "@github/copilot-sdk";

const session = await client.createSession({
    model: "gpt-5",
    tools: [
        defineTool("lookup_issue", {
            description: "從我們的追蹤器中獲取問題詳細資訊",
            parameters: z.object({
                id: z.string().describe("問題識別碼"),
            }),
            handler: async ({ id }) => {
                const issue = await fetchIssue(id);
                return issue;
            },
        }),
    ],
});
```

當 Copilot 調用 `lookup_issue` 時，用戶端會自動執行您的處理常式並回應 CLI。處理常式可以傳回任何可 JSON 序列化的值 (會自動封裝)、簡單的字串或用於完整控制結果中繼資料的 `ToolResultObject`。如果不想要使用 Zod，也支援原始 JSON 架構。

#### 覆蓋內建工具

如果您註冊了一個與內建 CLI 工具同名的工具 (例如 `edit_file`、`read_file`)，除非您透過設定 `overridesBuiltInTool: true` 明確加入，否則 SDK 將擲回錯誤。此旗標表示您打算使用自訂實作取代內建工具。

```ts
defineTool("edit_file", {
    description: "具有專案特定驗證的自訂檔案編輯器",
    parameters: z.object({ path: z.string(), content: z.string() }),
    overridesBuiltInTool: true,
    handler: async ({ path, content }) => { /* 您的邏輯 */ },
})
```

### 系統訊息自訂

使用工作階段設定中的 `systemMessage` 控制系統提示：

```typescript
const session = await client.createSession({
    model: "gpt-5",
    systemMessage: {
        content: `
<workflow_rules>
- 始終檢查安全性弱點
- 在適用時建議效能改進
</workflow_rules>
`,
    },
});
```

SDK 會自動注入環境內容、工具指令和安全防護欄。預設的 CLI 人格會被保留，您的 `content` 會附加在 SDK 管理的區段之後。要更改人格或完全重新定義提示，請使用 `mode: "replace"`。

如需完整控制 (移除所有防護欄)，請使用 `mode: "replace"`：

```typescript
const session = await client.createSession({
    model: "gpt-5",
    systemMessage: {
        mode: "replace",
        content: "你是一個樂於助人的助手。",
    },
});
```

### 無限工作階段 (Infinite Sessions)

預設情況下，工作階段使用 **無限工作階段**，它透過背景壓縮自動管理內容視窗限制，並將狀態持久化到工作區目錄。

```typescript
// 預設：啟用具有預設閾值的無限工作階段
const session = await client.createSession({ model: "gpt-5" });

// 存取檢查點和檔案的工作區路徑
console.log(session.workspacePath);
// => ~/.copilot/session-state/{sessionId}/

// 自訂閾值
const session = await client.createSession({
    model: "gpt-5",
    infiniteSessions: {
        enabled: true,
        backgroundCompactionThreshold: 0.80, // 在內容使用率達到 80% 時開始壓縮
        bufferExhaustionThreshold: 0.95, // 在達到 95% 時封鎖，直到壓縮完成
    },
});

// 停用無限工作階段
const session = await client.createSession({
    model: "gpt-5",
    infiniteSessions: { enabled: false },
});
```

啟用時，工作階段會發出壓縮事件：

- `session.compaction_start` - 背景壓縮已開始
- `session.compaction_complete` - 壓縮已完成 (包括權杖計數)

### 多個工作階段

```typescript
const session1 = await client.createSession({ model: "gpt-5" });
const session2 = await client.createSession({ model: "claude-sonnet-4.5" });

// 兩個工作階段是獨立的
await session1.sendAndWait({ prompt: "來自工作階段 1 的哈囉" });
await session2.sendAndWait({ prompt: "來自工作階段 2 的哈囉" });
```

### 自訂工作階段 ID

```typescript
const session = await client.createSession({
    sessionId: "my-custom-session-id",
    model: "gpt-5",
});
```

### 檔案附件

```typescript
await session.send({
    prompt: "分析此檔案",
    attachments: [
        {
            type: "file",
            path: "/path/to/file.js",
            displayName: "我的檔案",
        },
    ],
});
```

### 自訂提供者

SDK 支援自訂的 OpenAI 相容 API 提供者 (BYOK - 自備金鑰)，包括像 Ollama 這樣的本地提供者。使用自訂提供者時，您必須明確指定 `model`。

**ProviderConfig:**

- `type?: "openai" | "azure" | "anthropic"` - 提供者類型 (預設："openai")
- `baseUrl: string` - API 端點 URL (必填)
- `apiKey?: string` - API 金鑰 (對於像 Ollama 這樣的本地提供者是選用的)
- `bearerToken?: string` - 身分驗證的 Bearer 權杖 (優先於 apiKey)
- `wireApi?: "completions" | "responses"` - OpenAI/Azure 的 API 格式 (預設："completions")
- `azure?.apiVersion?: string` - Azure API 版本 (預設："2024-10-21")

**Ollama 範例：**

```typescript
const session = await client.createSession({
    model: "deepseek-coder-v2:16b", // 使用自訂提供者時必填
    provider: {
        type: "openai",
        baseUrl: "http://localhost:11434/v1", // Ollama 端點
        // Ollama 不需要 apiKey
    },
});

await session.sendAndWait({ prompt: "哈囉！" });
```

**自訂 OpenAI 相容 API 範例：**

```typescript
const session = await client.createSession({
    model: "gpt-4",
    provider: {
        type: "openai",
        baseUrl: "https://my-api.example.com/v1",
        apiKey: process.env.MY_API_KEY,
    },
});
```

**Azure OpenAI 範例：**

```typescript
const session = await client.createSession({
    model: "gpt-4",
    provider: {
        type: "azure",  // 對於 Azure 端點必須是 "azure"，而不是 "openai"
        baseUrl: "https://my-resource.openai.azure.com",  // 僅為主機，無路徑
        apiKey: process.env.AZURE_OPENAI_KEY,
        azure: {
            apiVersion: "2024-10-21",
        },
    },
});
```

> **重要注意事項：**
> - 使用自訂提供者時，`model` 參數是 **必填的**。如果未指定模型，SDK 將擲回錯誤。
> - 對於 Azure OpenAI 端點 (`*.openai.azure.com`)，您 **必須** 使用 `type: "azure"`，而不是 `type: "openai"`。
> - `baseUrl` 應該只是主機 (例如 `https://my-resource.openai.azure.com`)。**不要** 在 URL 中包含 `/openai/v1` —— SDK 會自動處理路徑建構。

## 使用者輸入請求

透過提供 `onUserInputRequest` 處理常式，讓代理能夠使用 `ask_user` 工具向使用者提問：

```typescript
const session = await client.createSession({
    model: "gpt-5",
    onUserInputRequest: async (request, invocation) => {
        // request.question - 要問的問題
        // request.choices - 選用的多選選項陣列
        // request.allowFreeform - 是否允許自由格式輸入 (預設：true)

        console.log(`代理詢問：${request.question}`);
        if (request.choices) {
            console.log(`選項：${request.choices.join(", ")}`);
        }

        // 傳回使用者的回應
        return {
            answer: "使用者在此回答",
            wasFreeform: true, // 回答是否為自由格式 (非來自選項)
        };
    },
});
```

## 工作階段 Hook

透過在 `hooks` 設定中提供處理常式來連結工作階段生命週期事件：

```typescript
const session = await client.createSession({
    model: "gpt-5",
    hooks: {
        // 在每次工具執行之前呼叫
        onPreToolUse: async (input, invocation) => {
            console.log(`即將執行工具：${input.toolName}`);
            // 傳回權限決策並選擇性地修改引數
            return {
                permissionDecision: "allow", // "allow", "deny" 或 "ask"
                modifiedArgs: input.toolArgs, // 選擇性地修改工具引數
                additionalContext: "模型的額外內容",
            };
        },

        // 在每次工具執行之後呼叫
        onPostToolUse: async (input, invocation) => {
            console.log(`工具 ${input.toolName} 已完成`);
            // 選擇性地修改結果或新增內容
            return {
                additionalContext: "執行後筆記",
            };
        },

        // 當使用者提交提示時呼叫
        onUserPromptSubmitted: async (input, invocation) => {
            console.log(`使用者提示：${input.prompt}`);
            return {
                modifiedPrompt: input.prompt, // 選擇性地修改提示
            };
        },

        // 當工作階段開始時呼叫
        onSessionStart: async (input, invocation) => {
            console.log(`工作階段從 ${input.source} 開始`); // "startup", "resume", "new"
            return {
                additionalContext: "工作階段初始化內容",
            };
        },

        // 當工作階段結束時呼叫
        onSessionEnd: async (input, invocation) => {
            console.log(`工作階段結束：${input.reason}`);
        },

        // 當發生錯誤時呼叫
        onErrorOccurred: async (input, invocation) => {
            console.error(`在 ${input.errorContext} 中發生錯誤：${input.error}`);
            return {
                errorHandling: "retry", // "retry", "skip" 或 "abort"
            };
        },
    },
});
```

**可用的 Hook：**

- `onPreToolUse` - 在執行前攔截工具呼叫。可以允許/拒絕或修改引數。
- `onPostToolUse` - 在執行後處理工具結果。可以修改結果或新增內容。
- `onUserPromptSubmitted` - 攔截使用者提示。可以在處理前修改提示。
- `onSessionStart` - 在工作階段開始或恢復時執行邏輯。
- `onSessionEnd` - 工作階段結束時的清理或記錄。
- `onErrorOccurred` - 使用重試/跳過/中止策略處理錯誤。

## 錯誤處理

```typescript
try {
    const session = await client.createSession();
    await session.send({ prompt: "哈囉" });
} catch (error) {
    console.error("錯誤：", error.message);
}
```

## 需求

- Node.js >= 18.0.0
- 已安裝 GitHub Copilot CLI 並位於 PATH 中 (或提供自訂 `cliPath`)

## 授權

MIT
