# 更新日誌

本檔案記錄了 Copilot SDK 的所有重大變更。

此更新日誌是在發布穩定版本時由 AI 代理程式自動產生的。
請參閱 [GitHub Releases](https://github.com/github/copilot-sdk/releases) 以獲取完整列表。

## [v0.1.32](https://github.com/github/copilot-sdk/releases/tag/v0.1.32) (2026-03-07)

### 功能：與 v2 CLI 伺服器的回溯相容性

針對 v3 API 編寫的 SDK 應用程式現在也可以在連接到 v2 CLI 伺服器時運作，無需更改任何程式碼。SDK 會偵測伺服器的通訊協定版本，並自動將 v2 的 `tool.call` 和 `permission.request` 訊息改編為 v3 所使用的相同面向使用者的處理常式。([#706](https://github.com/github/copilot-sdk/pull/706))

```ts
const session = await client.createSession({
  tools: [myTool],           // 未變更 — 適用於 v2 和 v3 伺服器
  onPermissionRequest: approveAll,
});
```

```cs
var session = await client.CreateSessionAsync(new SessionConfig {
    Tools = [myTool],          // 未變更 — 適用於 v2 和 v3 伺服器
    OnPermissionRequest = approveAll,
});
```

## [v0.1.31](https://github.com/github/copilot-sdk/releases/tag/v0.1.31) (2026-03-07)

### 功能：多用戶端工具與權限廣播 (通訊協定 v3)

SDK 現在使用通訊協定版本 3，其中執行環境會將 `external_tool.requested` 和 `permission.requested` 作為工作階段事件廣播給所有連接的用戶端。這支援了多用戶端架構，其中不同的用戶端提供不同的工具，或者多個用戶端觀察相同的權限提示 — 如果一個用戶端核准，所有用戶端都會看到結果。您現有的工具和權限處理常式程式碼無需變更。([#686](https://github.com/github/copilot-sdk/pull/686))

```ts
// 兩個用戶端各別註冊不同的工具；代理程式可以同時使用兩者
const session1 = await client1.createSession({
  tools: [defineTool("search", { handler: doSearch })],
  onPermissionRequest: approveAll,
});
const session2 = await client2.resumeSession(session1.id, {
  tools: [defineTool("analyze", { handler: doAnalyze })],
  onPermissionRequest: approveAll,
});
```

```cs
var session1 = await client1.CreateSessionAsync(new SessionConfig {
    Tools = [AIFunctionFactory.Create(DoSearch, "search")],
    OnPermissionRequest = PermissionHandlers.ApproveAll,
});
var session2 = await client2.ResumeSessionAsync(session1.Id, new ResumeSessionConfig {
    Tools = [AIFunctionFactory.Create(DoAnalyze, "analyze")],
    OnPermissionRequest = PermissionHandlers.ApproveAll,
});
```

### 功能：適用於 .NET 和 Go 的強型別 `PermissionRequestResultKind`

不再需要將 `result.Kind` 與難以發現的神祕字串（如 `"approved"` 或 `"denied-interactively-by-user"`）進行比較，.NET 和 Go 現在提供了型別常數。Node 和 Python 已經有了針對此內容的型別等價物；這實現了完全一致性。([#631](https://github.com/github/copilot-sdk/pull/631))

```cs
session.OnPermissionCompleted += (e) => {
    if (e.Result.Kind == PermissionRequestResultKind.Approved) { /* ... */ }
    if (e.Result.Kind == PermissionRequestResultKind.DeniedInteractivelyByUser) { /* ... */ }
};
```

```go
// Go: PermissionKindApproved, PermissionKindDeniedByRules,
//     PermissionKindDeniedCouldNotRequestFromUser, PermissionKindDeniedInteractivelyByUser
if result.Kind == copilot.PermissionKindApproved { /* ... */ }
```

### 其他變更

- 功能：**[Python]** **[Go]** 新增 `get_last_session_id()` / `GetLastSessionID()` 以實現 SDK 範圍內的一致性 (Node 和 .NET 之前已提供) ([#671](https://github.com/github/copilot-sdk/pull/671))
- 改進：**[Python]** 為產生的 RPC 方法新增 `timeout` 參數，允許呼叫者覆蓋長執行作業預設的 30 秒逾時時間 ([#681](https://github.com/github/copilot-sdk/pull/681))
- 錯誤修復：**[Go]** `PermissionRequest` 欄位現在已正確設定型別 (`ToolName`、`Diff`、`Path` 等)，而不是通用的 `Extra map[string]any` ([#685](https://github.com/github/copilot-sdk/pull/685))

## [v0.1.30](https://github.com/github/copilot-sdk/releases/tag/v0.1.30) (2026-03-03)

### 功能：支援覆蓋內建工具

應用程式現在可以覆蓋內建工具，例如 `grep`、`edit_file` 或 `read_file`。若要執行此操作，請註冊一個同名的自定義工具並設定覆蓋旗標。如果不設定旗標，當名稱與內建工具衝突時，執行環境將會回傳錯誤。([#636](https://github.com/github/copilot-sdk/pull/636))

```ts
import { defineTool } from "@github/copilot-sdk";

const session = await client.createSession({
  tools: [defineTool("grep", {
    overridesBuiltInTool: true,
    handler: async (params) => `CUSTOM_GREP_RESULT: ${params.query}`,
  })],
  onPermissionRequest: approveAll,
});
```

```cs
var grep = AIFunctionFactory.Create(
    ([Description("Search query")] string query) => $"CUSTOM_GREP_RESULT: {query}",
    "grep",
    "Custom grep implementation",
    new AIFunctionFactoryOptions
    {
        AdditionalProperties = new ReadOnlyDictionary<string, object?>(
            new Dictionary<string, object?> { ["is_override"] = true })
    });
```

### 功能：在工作階段中切換模型的更簡便 API

雖然 `session.rpc.model.switchTo()` 已經可以使用，但現在直接在工作階段物件上提供了一個簡便方法。([#621](https://github.com/github/copilot-sdk/pull/621))

- TypeScript: `await session.setModel("gpt-4.1")`
- C#: `await session.SetModelAsync("gpt-4.1")`
- Python: `await session.set_model("gpt-4.1")`
- Go: `err := session.SetModel(ctx, "gpt-4.1")`

### 其他變更

- 改進：**[C#]** 使用事件委派進行執行緒安全、按插入順序排序的事件處理常式發送 ([#624](https://github.com/github/copilot-sdk/pull/624))
- 改進：**[C#]** 去除 `OnDisposeCall` 的重複並改進實作 ([#626](https://github.com/github/copilot-sdk/pull/626))
- 改進：**[C#]** 移除處理常式欄位中不必要的 `SemaphoreSlim` 鎖定 ([#625](https://github.com/github/copilot-sdk/pull/625))
- 錯誤修復：**[Python]** 修正 `PermissionHandler.approve_all` 的型別註解 ([#618](https://github.com/github/copilot-sdk/pull/618))

### 新貢獻者

- @giulio-leone 在 [#618](https://github.com/github/copilot-sdk/pull/618) 中做出了他們的第一個貢獻
