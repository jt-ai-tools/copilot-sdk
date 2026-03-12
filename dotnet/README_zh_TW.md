# Copilot SDK

用於以程式化方式控制 GitHub Copilot CLI 的 SDK。

> **注意：** 此 SDK 處於技術預覽階段，可能會發生破壞性變更。

## 安裝

```bash
dotnet add package GitHub.Copilot.SDK
```

## 執行範例

嘗試互動式聊天範例 (從儲存庫根目錄)：

```bash
cd dotnet/samples
dotnet run
```

## 快速入門

```csharp
using GitHub.Copilot.SDK;

// 建立並啟動用戶端
await using var client = new CopilotClient();
await client.StartAsync();

// 建立一個工作階段
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5"
});

// 使用 session.idle 事件等待回應
var done = new TaskCompletionSource();

session.On(evt =>
{
    if (evt is AssistantMessageEvent msg)
    {
        Console.WriteLine(msg.Data.Content);
    }
    else if (evt is SessionIdleEvent)
    {
        done.SetResult();
    }
});

// 發送訊息並等待完成
await session.SendAsync(new MessageOptions { Prompt = "2+2 等於多少？" });
await done.Task;
```

## API 參考

### CopilotClient

#### 建構函式

```csharp
new CopilotClient(CopilotClientOptions? options = null)
```

**選項：**

- `CliPath` - CLI 執行檔路徑 (預設：來自 PATH 的 "copilot")
- `CliArgs` - 在 SDK 管理的旗標之前附加的額外引數
- `CliUrl` - 要連接的現有 CLI 伺服器 URL (例如 `"localhost:8080"`)。提供後，用戶端將不會衍生 CLI 程序。
- `Port` - 伺服器連接埠 (預設：0 表示隨機)
- `UseStdio` - 使用 stdio 傳輸而非 TCP (預設：true)
- `LogLevel` - 記錄層級 (預設："info")
- `AutoStart` - 自動啟動伺服器 (預設：true)
- `AutoRestart` - 當機時自動重新啟動 (預設：true)
- `Cwd` - CLI 程序的目前工作目錄
- `Environment` - 要傳遞給 CLI 程序環境變數
- `Logger` - 用於 SDK 記錄的 `ILogger` 執行個體
- `GitHubToken` - 用於身分驗證的 GitHub 權杖。提供後，優先於其他驗證方法。
- `UseLoggedInUser` - 是否使用已登入使用者進行身分驗證 (預設：true，但提供 `GitHubToken` 時為 false)。不能與 `CliUrl` 一起使用。

#### 方法

##### `StartAsync(): Task`

啟動 CLI 伺服器並建立連接。

##### `StopAsync(): Task`

停止伺服器並關閉所有工作階段。如果在清理過程中遇到錯誤，則擲回異常。

##### `ForceStopAsync(): Task`

強制停止 CLI 伺服器而不進行正常清理。當 `StopAsync()` 花費太長時間時使用。

##### `CreateSessionAsync(SessionConfig? config = null): Task<CopilotSession>`

建立一個新的對話工作階段。

**設定：**

- `SessionId` - 自訂工作階段 ID
- `Model` - 要使用的模型 ("gpt-5"、"claude-sonnet-4.5" 等)
- `ReasoningEffort` - 支援模型的推理努力層級 ("low", "medium", "high", "xhigh")。使用 `ListModelsAsync()` 檢查哪些模型支援此選項。
- `Tools` - 公開給 CLI 的自訂工具
- `SystemMessage` - 系統訊息自訂
- `AvailableTools` - 允許使用的工具名稱列表
- `ExcludedTools` - 要停用的工具名稱列表
- `Provider` - 自訂 API 提供者設定 (BYOK)
- `Streaming` - 啟用回應區塊的串流 (預設：false)
- `InfiniteSessions` - 設定自動內容壓縮 (見下文)
- `OnUserInputRequest` - 來自代理的使用者輸入請求處理常式 (啟用 ask_user 工具)。請參閱 [使用者輸入請求](#user-input-requests) 章節。
- `Hooks` - 工作階段生命週期事件的 Hook 處理常式。請參閱 [工作階段 Hook](#session-hooks) 章節。

##### `ResumeSessionAsync(string sessionId, ResumeSessionConfig? config = null): Task<CopilotSession>`

恢復現有工作階段。如果啟用了無限工作階段，則傳回已填寫 `WorkspacePath` 的工作階段。

##### `PingAsync(string? message = null): Task<PingResponse>`

偵測伺服器以檢查連線。

##### `State: ConnectionState`

獲取當前連線狀態。

##### `ListSessionsAsync(): Task<List<SessionMetadata>>`

列出所有可用的工作階段。

##### `DeleteSessionAsync(string sessionId): Task`

從磁碟刪除工作階段及其資料。

##### `GetForegroundSessionIdAsync(): Task<string?>`

獲取當前在 TUI 中顯示的工作階段 ID。僅在連接到以 TUI+伺服器模式 (`--ui-server`) 執行的伺服器時可用。

##### `SetForegroundSessionIdAsync(string sessionId): Task`

請求 TUI 切換到顯示指定的工作階段。僅在 TUI+伺服器模式下可用。

##### `On(Action<SessionLifecycleEvent> handler): IDisposable`

訂閱所有工作階段生命週期事件。傳回一個在處置 (disposed) 時取消訂閱的 `IDisposable`。

```csharp
using var subscription = client.On(evt =>
{
    Console.WriteLine($"工作階段 {evt.SessionId}: {evt.Type}");
});
```

##### `On(string eventType, Action<SessionLifecycleEvent> handler): IDisposable`

訂閱特定的生命週期事件類型。使用 `SessionLifecycleEventTypes` 常數。

```csharp
using var subscription = client.On(SessionLifecycleEventTypes.Foreground, evt =>
{
    Console.WriteLine($"工作階段 {evt.SessionId} 現在處於前景");
});
```

**生命週期事件類型：**
- `SessionLifecycleEventTypes.Created` - 建立了一個新的工作階段
- `SessionLifecycleEventTypes.Deleted` - 刪除了一個工作階段
- `SessionLifecycleEventTypes.Updated` - 更新了一個工作階段
- `SessionLifecycleEventTypes.Foreground` - 工作階段成為 TUI 中的前景工作階段
- `SessionLifecycleEventTypes.Background` - 工作階段不再是前景工作階段

---

### CopilotSession

代表單個對話工作階段。

#### 屬性

- `SessionId` - 此工作階段的唯一識別碼
- `WorkspacePath` - 啟用無限工作階段時的工作階段工作區目錄路徑。包含 `checkpoints/`、`plan.md` 和 `files/` 子目錄。如果停用無限工作階段，則為 null。

#### 方法

##### `SendAsync(MessageOptions options): Task<string>`

向工作階段發送訊息。

**選項：**

- `Prompt` - 要發送的訊息/提示
- `Attachments` - 檔案附件
- `Mode` - 傳送模式 ("enqueue" 或 "immediate")

傳回訊息 ID。

##### `On(SessionEventHandler handler): IDisposable`

訂閱工作階段事件。傳回一個用於取消訂閱的可處置物件。

```csharp
var subscription = session.On(evt =>
{
    Console.WriteLine($"事件：{evt.Type}");
});

// 稍後...
subscription.Dispose();
```

##### `AbortAsync(): Task`

中止此工作階段中目前正在處理的訊息。

##### `GetMessagesAsync(): Task<IReadOnlyList<SessionEvent>>`

獲取此工作階段的所有事件/訊息。

##### `DisposeAsync(): ValueTask`

關閉工作階段並釋放記憶體資源。磁碟上的工作階段資料將被保留 —— 稍後可以透過 `ResumeSessionAsync()` 恢復對話。要永久刪除工作階段資料，請使用 `client.DeleteSessionAsync()`。

```csharp
// 建議：透過 await using 進行自動清理
await using var session = await client.CreateSessionAsync(config);
// 離開範圍時，session 會自動被處置

// 替代方案：明確處置
var session2 = await client.CreateSessionAsync(config);
await session2.DisposeAsync();
```

---

## 事件類型

工作階段在處理過程中會發出各種事件。每種事件類型都是一個繼承自 `SessionEvent` 的類別：

- `UserMessageEvent` - 新增了使用者訊息
- `AssistantMessageEvent` - 助理回應
- `ToolExecutionStartEvent` - 工具執行開始
- `ToolExecutionCompleteEvent` - 工具執行完成
- `SessionStartEvent` - 工作階段已開始
- `SessionIdleEvent` - 工作階段已閒置
- `SessionErrorEvent` - 發生工作階段錯誤
- 以及更多...

使用模式比對來處理特定的事件類型：

```csharp
session.On(evt =>
{
    switch (evt)
    {
        case AssistantMessageEvent msg:
            Console.WriteLine(msg.Data.Content);
            break;
        case SessionErrorEvent err:
            Console.WriteLine($"錯誤：{err.Data.Message}");
            break;
    }
});
```

## 影像支援

SDK 透過 `Attachments` 參數支援影像附件。您可以透過提供影像檔案路徑來附加影像：

```csharp
await session.SendAsync(new MessageOptions
{
    Prompt = "這張影像中是什麼？",
    Attachments = new List<UserMessageDataAttachmentsItem>
    {
        new UserMessageDataAttachmentsItem
        {
            Type = UserMessageDataAttachmentsItemType.File,
            Path = "/path/to/image.jpg"
        }
    }
});
```

支援的影像格式包括 JPG、PNG、GIF 和其他常見影像類型。代理的 `view` 工具也可以直接從檔案系統讀取影像，因此您也可以提出如下問題：

```csharp
await session.SendAsync(new MessageOptions { Prompt = "此目錄中最近的 jpg 描繪了什麼？" });
```

## 串流 (Streaming)

啟用串流以在產生助理回應區塊時接收它們：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    Streaming = true
});

// 使用 TaskCompletionSource 等待完成
var done = new TaskCompletionSource();

session.On(evt =>
{
    switch (evt)
    {
        case AssistantMessageDeltaEvent delta:
            // 串流訊息區塊 - 增量列印
            Console.Write(delta.Data.DeltaContent);
            break;
        case AssistantReasoningDeltaEvent reasoningDelta:
            // 串流推理區塊 (如果模型支援推理)
            Console.Write(reasoningDelta.Data.DeltaContent);
            break;
        case AssistantMessageEvent msg:
            // 最終訊息 - 完整內容
            Console.WriteLine("\n--- 最終訊息 ---");
            Console.WriteLine(msg.Data.Content);
            break;
        case AssistantReasoningEvent reasoningEvt:
            // 最終推理內容 (如果模型支援推理)
            Console.WriteLine("--- 推理 ---");
            Console.WriteLine(reasoningEvt.Data.Content);
            break;
        case SessionIdleEvent:
            // 工作階段處理完成
            done.SetResult();
            break;
    }
});

await session.SendAsync(new MessageOptions { Prompt = "給我講個短篇故事" });
await done.Task; // 等待串流完成
```

當 `Streaming = true` 時：

- 發送 `AssistantMessageDeltaEvent` 事件，其中 `DeltaContent` 包含增量文字
- 發送 `AssistantReasoningDeltaEvent` 事件，其中 `DeltaContent` 用於推理/思維鏈 (取決於模型)
- 累加 `DeltaContent` 值以逐步建立完整回應
- 最終的 `AssistantMessageEvent` 和 `AssistantReasoningEvent` 事件包含完整內容

注意：無論串流設定如何，始終會發送 `AssistantMessageEvent` 和 `AssistantReasoningEvent` (最終事件)。

## 無限工作階段 (Infinite Sessions)

預設情況下，工作階段使用 **無限工作階段**，它透過背景壓縮自動管理內容視窗限制，並將狀態持久化到工作區目錄。

```csharp
// 預設：啟用具有預設閾值的無限工作階段
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5"
});

// 存取檢查點和檔案的工作區路徑
Console.WriteLine(session.WorkspacePath);
// => ~/.copilot/session-state/{sessionId}/

// 自訂閾值
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    InfiniteSessions = new InfiniteSessionConfig
    {
        Enabled = true,
        BackgroundCompactionThreshold = 0.80, // 在內容使用率達到 80% 時開始壓縮
        BufferExhaustionThreshold = 0.95      // 在達到 95% 時封鎖，直到壓縮完成
    }
});

// 停用無限工作階段
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    InfiniteSessions = new InfiniteSessionConfig { Enabled = false }
});
```

啟用時，工作階段會發出壓縮事件：

- `SessionCompactionStartEvent` - 背景壓縮已開始
- `SessionCompactionCompleteEvent` - 壓縮已完成 (包括權杖計數)

## 進階用法

### 手動伺服器控制

```csharp
var client = new CopilotClient(new CopilotClientOptions { AutoStart = false });

// 手動啟動
await client.StartAsync();

// 使用用戶端...

// 手動停止
await client.StopAsync();
```

### 工具

當模型需要您擁有的功能時，您可以讓 CLI 回呼您的程序。使用來自 Microsoft.Extensions.AI 的 `AIFunctionFactory.Create` 進行類型安全的工具定義：

```csharp
using Microsoft.Extensions.AI;
using System.ComponentModel;

var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    Tools = [
        AIFunctionFactory.Create(
            async ([Description("問題識別碼")] string id) => {
                var issue = await FetchIssueAsync(id);
                return issue;
            },
            "lookup_issue",
            "從我們的追蹤器獲取問題詳細資訊"),
    ]
});
```

當 Copilot 調用 `lookup_issue` 時，用戶端會自動執行您的處理常式並回應 CLI。處理常式可以傳回任何可 JSON 序列化的值 (會自動封裝)，或是一個封裝 `ToolResultObject` 的 `ToolResultAIContent` 以實現對結果中繼資料的完整控制。

#### 覆蓋內建工具

如果您註冊了一個與內建 CLI 工具同名的工具 (例如 `edit_file`、`read_file`)，除非您透過在工具的 `AdditionalProperties` 中設定 `is_override` 明確加入，否則執行階段將傳回錯誤。此旗標表示您打算使用自訂實作取代內建工具。

```csharp
var editFile = AIFunctionFactory.Create(
    async ([Description("檔案路徑")] string path, [Description("新內容")] string content) => {
        // 您的邏輯
    },
    "edit_file",
    "具有專案特定驗證的自訂檔案編輯器",
    new AIFunctionFactoryOptions
    {
        AdditionalProperties = new ReadOnlyDictionary<string, object?>(
            new Dictionary<string, object?> { ["is_override"] = true })
    });

var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    Tools = [editFile],
});
```

### 系統訊息自訂

使用工作階段設定中的 `SystemMessage` 控制系統提示：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    SystemMessage = new SystemMessageConfig
    {
        Mode = SystemMessageMode.Append,
        Content = @"
<workflow_rules>
- 始終檢查安全性弱點
- 在適用時建議效能改進
</workflow_rules>
"
    }
});
```

如需完整控制 (移除所有防護欄)，請使用 `Mode = SystemMessageMode.Replace`：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    SystemMessage = new SystemMessageConfig
    {
        Mode = SystemMessageMode.Replace,
        Content = "你是一個樂於助人的助手。"
    }
});
```

### 多個工作階段

```csharp
var session1 = await client.CreateSessionAsync(new SessionConfig { Model = "gpt-5" });
var session2 = await client.CreateSessionAsync(new SessionConfig { Model = "claude-sonnet-4.5" });

// 兩個工作階段是獨立的
await session1.SendAsync(new MessageOptions { Prompt = "來自工作階段 1 的哈囉" });
await session2.SendAsync(new MessageOptions { Prompt = "來自工作階段 2 的哈囉" });
```

### 檔案附件

```csharp
await session.SendAsync(new MessageOptions
{
    Prompt = "分析此檔案",
    Attachments = new List<UserMessageDataAttachmentsItem>
    {
        new UserMessageDataAttachmentsItem
        {
            Type = UserMessageDataAttachmentsItemType.File,
            Path = "/path/to/file.cs",
            DisplayName = "我的檔案"
        }
    }
});
```

### 自備金鑰 (BYOK)

使用自訂 API 提供者：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Provider = new ProviderConfig
    {
        Type = "openai",
        BaseUrl = "https://api.openai.com/v1",
        ApiKey = "您的 API 金鑰"
    }
});
```

## 使用者輸入請求

透過提供 `OnUserInputRequest` 處理常式，讓代理能夠使用 `ask_user` 工具向使用者提問：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    OnUserInputRequest = async (request, invocation) =>
    {
        // request.Question - 要問的問題
        // request.Choices - 選用的多選選項列表
        // request.AllowFreeform - 是否允許自由格式輸入 (預設：true)

        Console.WriteLine($"代理詢問：{request.Question}");
        if (request.Choices?.Count > 0)
        {
            Console.WriteLine($"選項：{string.Join(", ", request.Choices)}");
        }

        // 傳回使用者的回應
        return new UserInputResponse
        {
            Answer = "使用者在此回答",
            WasFreeform = true // 回答是否為自由格式 (非來自選項)
        };
    }
});
```

## 工作階段 Hook

透過在 `Hooks` 設定中提供處理常式來連結工作階段生命週期事件：

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-5",
    Hooks = new SessionHooks
    {
        // 在每次工具執行之前呼叫
        OnPreToolUse = async (input, invocation) =>
        {
            Console.WriteLine($"即將執行工具：{input.ToolName}");
            // 傳回權限決策並選擇性地修改引數
            return new PreToolUseHookOutput
            {
                PermissionDecision = "allow", // "allow", "deny" 或 "ask"
                ModifiedArgs = input.ToolArgs, // 選擇性地修改工具引數
                AdditionalContext = "模型的額外內容"
            };
        },

        // 在每次工具執行之後呼叫
        OnPostToolUse = async (input, invocation) =>
        {
            Console.WriteLine($"工具 {input.ToolName} 已完成");
            return new PostToolUseHookOutput
            {
                AdditionalContext = "執行後筆記"
            };
        },

        // 當使用者提交提示時呼叫
        OnUserPromptSubmitted = async (input, invocation) =>
        {
            Console.WriteLine($"使用者提示：{input.Prompt}");
            return new UserPromptSubmittedHookOutput
            {
                ModifiedPrompt = input.Prompt // 選擇性地修改提示
            };
        },

        // 當工作階段開始時呼叫
        OnSessionStart = async (input, invocation) =>
        {
            Console.WriteLine($"工作階段從 {input.Source} 開始"); // "startup", "resume", "new"
            return new SessionStartHookOutput
            {
                AdditionalContext = "工作階段初始化內容"
            };
        },

        // 當工作階段結束時呼叫
        OnSessionEnd = async (input, invocation) =>
        {
            Console.WriteLine($"工作階段結束：{input.Reason}");
            return null;
        },

        // 當發生錯誤時呼叫
        OnErrorOccurred = async (input, invocation) =>
        {
            Console.WriteLine($"在 {input.ErrorContext} 中發生錯誤：{input.Error}");
            return new ErrorOccurredHookOutput
            {
                ErrorHandling = "retry" // "retry", "skip" 或 "abort"
            };
        }
    }
});
```

**可用的 Hook：**

- `OnPreToolUse` - 在執行前攔截工具呼叫。可以允許/拒絕或修改引數。
- `OnPostToolUse` - 在執行後處理工具結果。可以修改結果或新增內容。
- `OnUserPromptSubmitted` - 攔截使用者提示。可以在處理前修改提示。
- `OnSessionStart` - 在工作階段開始或恢復時執行邏輯。
- `OnSessionEnd` - 工作階段結束時的清理或記錄。
- `OnErrorOccurred` - 使用重試/跳過/中止策略處理錯誤。

## 錯誤處理

```csharp
try
{
    var session = await client.CreateSessionAsync();
    await session.SendAsync(new MessageOptions { Prompt = "哈囉" });
}
catch (IOException ex)
{
    Console.Error.WriteLine($"通訊錯誤：{ex.Message}");
}
catch (Exception ex)
{
    Console.Error.WriteLine($"錯誤：{ex.Message}");
}
```

## 需求

- .NET 8.0 或更高版本
- 已安裝 GitHub Copilot CLI 並位於 PATH 中 (或提供自訂 `CliPath`)

## 授權

MIT
