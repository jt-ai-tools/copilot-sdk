# SDK 與 CLI 相容性

本文件概述了哪些 Copilot CLI 功能可透過 SDK 使用，以及哪些功能僅限 CLI 使用。

## 概覽

Copilot SDK 透過 JSON-RPC 協定與 CLI 進行通訊。功能必須明確地透過此協定公開，才能在 SDK 中使用。許多互動式 CLI 功能是特定於終端機的，無法以程式化方式使用。

## 功能比較

### ✅ SDK 中可用

| 功能 | SDK 方法 | 備註 |
|---------|------------|-------|
| **工作階段管理** | | |
| 建立工作階段 | `createSession()` | 完整設定支援 |
| 恢復工作階段 | `resumeSession()` | 搭配無限工作階段工作區 |
| 斷開工作階段 | `disconnect()` | 釋放記憶體資源 |
| 銷毀工作階段 *(已棄用)* | `destroy()` | 請改用 `disconnect()` |
| 刪除工作階段 | `deleteSession()` | 從儲存空間移除 |
| 列出工作階段 | `listSessions()` | 所有儲存的工作階段 |
| 獲取最後一個工作階段 | `getLastSessionId()` | 用於快速恢復 |
| 獲取前台工作階段 | `getForegroundSessionId()` | 多工作階段協調 |
| 設定前台工作階段 | `setForegroundSessionId()` | 多工作階段協調 |
| **訊息傳遞** | | |
| 發送訊息 | `send()` | 可帶附件 |
| 發送並等待 | `sendAndWait()` | 阻塞直到完成 |
| 引導 (Steering, 立即模式) | `send({ mode: "immediate" })` | 在輪次中插入訊息而不中止 |
| 排隊 (Queueing, 入隊模式) | `send({ mode: "enqueue" })` | 緩衝以進行順序處理 (預設) |
| 檔案附件 | `send({ attachments: [{ type: "file", path }] })` | 圖片會自動編碼並調整大小 |
| 目錄附件 | `send({ attachments: [{ type: "directory", path }] })` | 附加目錄內容 |
| 獲取歷史記錄 | `getMessages()` | 所有工作階段事件 |
| 中止 | `abort()` | 取消進行中的請求 |
| **工具** | | |
| 註冊自定義工具 | `registerTools()` | 完整 JSON Schema 支援 |
| 工具權限控制 | `onPreToolUse` 鉤子 (hook) | 允許/拒絕/詢問 |
| 工具結果修改 | `onPostToolUse` 鉤子 | 轉換結果 |
| 可用/排除工具 | `availableTools`, `excludedTools` 設定 | 過濾工具 |
| **模型** | | |
| 列出模型 | `listModels()` | 包含能力、計費、政策 |
| 設定模型 (建立時) | 工作階段設定中的 `model` | 按工作階段 |
| 切換模型 (中途) | `session.setModel()` | 亦可透過 `session.rpc.model.switchTo()` |
| 獲取當前模型 | `session.rpc.model.getCurrent()` | 查詢使用中的模型 |
| 推理強度 (Reasoning effort) | `reasoningEffort` 設定 | 適用於受支援的模型 |
| **代理程式模式 (Agent Mode)** | | |
| 獲取當前模式 | `session.rpc.mode.get()` | 傳回當前模式 |
| 設定模式 | `session.rpc.mode.set()` | 在模式間切換 |
| **計畫管理 (Plan Management)** | | |
| 讀取計畫 | `session.rpc.plan.read()` | 獲取 plan.md 內容與路徑 |
| 更新計畫 | `session.rpc.plan.update()` | 寫入 plan.md 內容 |
| 刪除計畫 | `session.rpc.plan.delete()` | 移除 plan.md |
| **工作區檔案** | | |
| 列出工作區檔案 | `session.rpc.workspace.listFiles()` | 工作階段工作區中的檔案 |
| 讀取工作區檔案 | `session.rpc.workspace.readFile()` | 讀取檔案內容 |
| 建立工作區檔案 | `session.rpc.workspace.createFile()` | 在工作區建立檔案 |
| **身份驗證** | | |
| 獲取驗證狀態 | `getAuthStatus()` | 檢查登入狀態 |
| 使用權杖 (Token) | `githubToken` 選項 | 程式化驗證 |
| **連線性** | | |
| Ping | `client.ping()` | 帶有伺服器時間戳記的健康檢查 |
| 獲取伺服器狀態 | `client.getStatus()` | 協定版本與伺服器資訊 |
| **MCP 伺服器** | | |
| 本地/stdio 伺服器 | `mcpServers` 設定 | 啟動程序 |
| 遠端 HTTP/SSE | `mcpServers` 設定 | 連接至服務 |
| **鉤子 (Hooks)** | | |
| 工具使用前 | `onPreToolUse` | 權限、修改參數 |
| 工具使用後 | `onPostToolUse` | 修改結果 |
| 使用者提示詞 | `onUserPromptSubmitted` | 修改提示詞 |
| 工作階段開始/結束 | `onSessionStart`, `onSessionEnd` | 包含來源/原因的生命週期 |
| 錯誤處理 | `onErrorOccurred` | 自定義處理 |
| **事件** | | |
| 所有工作階段事件 | `on()`, `once()` | 40 多種事件類型 |
| 串流 | `streaming: true` | Delta 事件 |
| **工作階段設定** | | |
| 自定義代理程式 | `customAgents` 設定 | 定義專門的代理程式 |
| 系統訊息 | `systemMessage` 設定 | 附加或替換 |
| 自定義提供者 | `provider` 設定 | BYOK 支援 |
| 無限工作階段 | `infiniteSessions` 設定 | 自動壓縮 |
| 權限處理器 | `onPermissionRequest` | 核准/拒絕請求 |
| 使用者輸入處理器 | `onUserInputRequest` | 處理 ask_user |
| 技能 (Skills) | `skillDirectories` 設定 | 自定義技能 |
| 停用技能 | `disabledSkills` 設定 | 停用特定技能 |
| 設定目錄 | `configDir` 設定 | 覆寫預設設定位置 |
| 用戶端名稱 | `clientName` 設定 | 在 User-Agent 中識別應用程式 |
| 工作目錄 | `workingDirectory` 設定 | 設定工作階段 cwd |
| **實驗性功能** | | |
| 代理程式管理 | `session.rpc.agent.*` | 列出、選擇、取消選擇、獲取當前代理程式 |
| 艦隊模式 (Fleet mode) | `session.rpc.fleet.start()` | 並行子代理程式執行 |
| 手動壓縮 | `session.rpc.compaction.compact()` | 視需求觸發壓縮 |

### ❌ SDK 中不可用 (僅限 CLI)

| 功能 | CLI 指令/選項 | 原因 |
|---------|-------------------|--------|
| **工作階段匯出** | | |
| 匯出至檔案 | `--share`, `/share` | 不在協定中 |
| 匯出至 gist | `--share-gist`, `/share gist` | 不在協定中 |
| **互動式 UI** | | |
| 斜線指令 | `/help`, `/clear`, `/exit` 等 | 僅限 TUI (終端機介面) |
| 代理程式選擇對話框 | `/agent` | 互動式 UI |
| Diff 模式對話框 | `/diff` | 互動式 UI |
| 回饋對話框 | `/feedback` | 互動式 UI |
| 主題選擇器 | `/theme` | 終端機 UI |
| 模型選擇器 | `/model` | 互動式 UI (請改用 SDK 的 `setModel()`) |
| 複製到剪貼簿 | `/copy` | 終端機相關 |
| 上下文管理 | `/context` | 互動式 UI |
| **研究與歷史** | | |
| 深度研究 (Deep research) | `/research` | 帶有網頁搜尋的 TUI 工作流 |
| 工作階段歷史工具 | `/chronicle` | Standup, tips, improve, reindex |
| **終端機功能** | | |
| 彩色輸出 | `--no-color` | 終端機相關 |
| 螢幕閱讀器模式 | `--screen-reader` | 無障礙功能 |
| 豐富的 diff 渲染 | `--plain-diff` | 終端機渲染 |
| 啟動橫幅 | `--banner` | 視覺元素 |
| 串流模式 | `/streamer-mode` | TUI 顯示模式 |
| 交替螢幕緩衝區 | `--alt-screen`, `--no-alt-screen` | 終端機渲染 |
| 滑鼠支援 | `--mouse`, `--no-mouse` | 終端機輸入 |
| **路徑/權限捷徑** | | |
| 允許所有路徑 | `--allow-all-paths` | 使用權限處理器 |
| 允許所有 URL | `--allow-all-urls` | 使用權限處理器 |
| 允許所有權限 | `--yolo`, `--allow-all`, `/allow-all` | 使用權限處理器 |
| 細粒度工具權限 | `--allow-tool`, `--deny-tool` | 使用 `onPreToolUse` 鉤子 |
| URL 存取控制 | `--allow-url`, `--deny-url` | 使用權限處理器 |
| 重設已允許的工具 | `/reset-allowed-tools` | TUI 指令 |
| **目錄管理** | | |
| 新增目錄 | `/add-dir`, `--add-dir` | 在工作階段中設定 |
| 列出目錄 | `/list-dirs` | TUI 指令 |
| 更改目錄 | `/cwd` | TUI 指令 |
| **插件/MCP 管理** | | |
| 插件指令 | `/plugin` | 互動式管理 |
| MCP 伺服器管理 | `/mcp` | 互動式 UI |
| **帳戶管理** | | |
| 登入流程 | `/login`, `copilot auth login` | OAuth 裝置流程 |
| 登出 | `/logout`, `copilot auth logout` | 直接透過 CLI |
| 使用者資訊 | `/user` | TUI 指令 |
| **工作階段操作** | | |
| 清除對話 | `/clear` | 僅限 TUI |
| 計畫視圖 | `/plan` | 僅限 TUI (請改用 SDK 的 `session.rpc.plan.*`) |
| 工作階段管理 | `/session`, `/resume`, `/rename` | TUI 工作流 |
| 艦隊模式 (互動式) | `/fleet` | 僅限 TUI (請改用 SDK 的 `session.rpc.fleet.start()`) |
| **技能管理** | | |
| 管理技能 | `/skills` | 互動式 UI |
| **任務管理** | | |
| 查看背景任務 | `/tasks` | TUI 指令 |
| **使用量與統計** | | |
| 權杖使用量 | `/usage` | 訂閱使用量事件 |
| **程式碼審查** | | |
| 審查變更 | `/review` | TUI 指令 |
| **委派** | | |
| 委派至 PR | `/delegate` | TUI 工作流 |
| **終端機設定** | | |
| 外殼 (Shell) 整合 | `/terminal-setup` | 特定於外殼 |
| **開發** | | |
| 切換實驗性功能 | `/experimental`, `--experimental` | 執行時期旗標 |
| 自定義指令控制 | `--no-custom-instructions` | CLI 旗標 |
| 診斷工作階段 | `/diagnose` | TUI 指令 |
| 查看/管理指示 | `/instructions` | TUI 指令 |
| 收集除錯記錄 | `/collect-debug-logs` | 診斷工具 |
| 重新索引工作區 | `/reindex` | TUI 指令 |
| IDE 整合 | `/ide` | 特定於 IDE 的工作流 |
| **非互動模式** | | |
| 提示模式 | `-p`, `--prompt` | 單次執行 |
| 互動式提示 | `-i`, `--interactive` | 自動執行後進入互動模式 |
| 靜默輸出 | `-s`, `--silent` | 腳本友善 |
| 繼續工作階段 | `--continue` | 恢復最近的一個 |
| 代理程式選擇 | `--agent <agent>` | CLI 旗標 |

## 解決方法

### 工作階段匯出

SDK 無法使用 `--share` 選項。解決方法：

1. **手動收集事件** - 訂閱工作階段事件並建構您自己的匯出：
   ```typescript
   const events: SessionEvent[] = [];
   session.on((event) => events.push(event));
   // ... 在對話結束後 ...
   const messages = await session.getMessages();
   // 自行格式化為 Markdown
   ```

2. **直接使用 CLI 進行匯出** - 對於一次性匯出，請使用 `--share` 執行 CLI。

### 權限控制

SDK 使用 **預設拒絕** 的權限模型。所有權限請求 (檔案寫入、外殼指令、URL 抓取等) 都會被拒絕，除非您的應用程式提供了 `onPermissionRequest` 處理器。

請使用權限處理器，而非 `--allow-all-paths` 或 `--yolo`：

```typescript
const session = await client.createSession({
  onPermissionRequest: approveAll,
});
```

### 權杖使用量追蹤

請訂閱使用量事件，而非使用 `/usage`：

```typescript
session.on("assistant.usage", (event) => {
  console.log("Tokens used:", {
    input: event.data.inputTokens,
    output: event.data.outputTokens,
  });
});
```

### 上下文壓縮 (Context Compaction)

請設定自動壓縮或手動觸發，而非使用 `/compact`：

```typescript
// 透過設定進行自動壓縮
const session = await client.createSession({
  infiniteSessions: {
    enabled: true,
    backgroundCompactionThreshold: 0.80,  // 在上下文使用率達到 80% 時開始背景壓縮
    bufferExhaustionThreshold: 0.95,      // 在上下文使用率達到 95% 時阻塞並壓縮
  },
});

// 手動壓縮 (實驗性)
const result = await session.rpc.compaction.compact();
console.log(`Removed ${result.tokensRemoved} tokens, ${result.messagesRemoved} messages`);
```

> **注意：** 閾值是上下文使用率 (0.0-1.0)，而非絕對權杖計數。

### 計畫管理

以程式化方式讀取與寫入工作階段計畫：

```typescript
// 讀取當前計畫
const plan = await session.rpc.plan.read();
if (plan.exists) {
  console.log(plan.content);
}

// 更新計畫
await session.rpc.plan.update({ content: "# My Plan\n- Step 1\n- Step 2" });

// 刪除計畫
await session.rpc.plan.delete();
```

### 訊息引導 (Message Steering)

在不中止當前 LLM 輪次的情況下插入訊息：

```typescript
// 在輪次中引導代理程式
await session.send({ prompt: "Focus on error handling first", mode: "immediate" });

// 預設：排隊至下一個輪次
await session.send({ prompt: "Next, add tests" });
```

## 協定限制

SDK 只能存取透過 CLI 的 JSON-RPC 協定公開的功能。如果您需要某項不可用的 CLI 功能：

1. **尋找替代方案** - 許多功能都有 SDK 等效項 (見上方的解決方法)
2. **直接使用 CLI** - 對於一次性操作，請呼叫 CLI
3. **請求功能** - 開啟 Issue 以請求協定支援

## 版本相容性

| SDK 協定範圍 | CLI 協定版本 | 相容性 |
|--------------------|---------------------|---------------|
| v2–v3 | v3 | 完整支援 |
| v2–v3 | v2 | 透過自動 v2 適配器支援 |

SDK 在啟動時會與 CLI 協商協定版本。SDK 支援協定版本 2 到 3。連接至 v2 CLI 伺服器時，SDK 會自動將 `tool.call` 與 `permission.request` 訊息適配至 v3 事件模型 —— 無須更改程式碼。

在執行時期檢查版本：

```typescript
const status = await client.getStatus();
console.log("Protocol version:", status.protocolVersion);
```

## 延伸閱讀

- [入門指南](../getting-started_zh_TW.md)
- [鉤子 (Hooks) 文件](../hooks/index_zh_TW.md)
- [MCP 伺服器指南](../features/mcp_zh_TW.md)
- [除錯指南](./debugging_zh_TW.md)
