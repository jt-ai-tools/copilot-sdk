# 適用於 Go 的 Copilot CLI SDK

用於以程式化方式存取 GitHub Copilot CLI 的 Go SDK。

> **注意：** 此 SDK 處於技術預覽階段，可能會發生破壞性變更。

## 安裝

```bash
go get github.com/github/copilot-sdk/go
```

## 執行範例

嘗試互動式聊天範例 (從儲存庫根目錄)：

```bash
cd go/samples
go run chat.go
```

## 快速入門

```go
package main

import (
	"context"
    "fmt"
    "log"

    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    // 建立用戶端
    client := copilot.NewClient(&copilot.ClientOptions{
        LogLevel: "error",
    })

    // 啟動用戶端
    if err := client.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
    defer client.Stop()

    // 建立一個工作階段
    session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
        Model: "gpt-5",
    })
    if err != nil {
        log.Fatal(err)
    }
    defer session.Disconnect()

    // 設定事件處理常式
    done := make(chan bool)
    session.On(func(event copilot.SessionEvent) {
        if event.Type == "assistant.message" {
            if event.Data.Content != nil {
                fmt.Println(*event.Data.Content)
            }
        }
        if event.Type == "session.idle" {
            close(done)
        }
    })

    // 發送訊息
    _, err = session.Send(context.Background(), copilot.MessageOptions{
        Prompt: "2+2 等於多少？",
    })
    if err != nil {
        log.Fatal(err)
    }

    // 等待完成
    <-done
}
```

## 散佈包含嵌入式 GitHub Copilot CLI 的應用程式

SDK 支援使用 Go 的 `embed` 套件將 Copilot CLI 二進位檔案捆綁在應用程式的散佈版本中。
這允許您捆綁特定的 CLI 版本，並避免使用者系統上的外部依賴。

按照以下步驟嵌入 CLI：

1. 執行 `go get -tool github.com/github/copilot-sdk/go/cmd/bundler`。這是每個專案一次性的設定步驟。
2. 在建置應用程式之前，在建置環境中執行 `go tool bundler`。

就這樣！當您的應用程式呼叫 `copilot.NewClient` 且沒有 `CLIPath` 或 `COPILOT_CLI_PATH` 環境變數時，SDK 將自動將嵌入的 CLI 安裝到快取目錄中，並將其用於所有操作。

## API 參考

### Client

- `NewClient(options *ClientOptions) *Client` - 建立新的用戶端
- `Start(ctx context.Context) error` - 啟動 CLI 伺服器
- `Stop() error` - 停止 CLI 伺服器
- `ForceStop()` - 強制停止而不進行正常清理
- `CreateSession(config *SessionConfig) (*Session, error)` - 建立新的工作階段
- `ResumeSession(sessionID string, config *ResumeSessionConfig) (*Session, error)` - 恢復現有工作階段
- `ResumeSessionWithOptions(sessionID string, config *ResumeSessionConfig) (*Session, error)` - 使用額外設定恢復
- `ListSessions(filter *SessionListFilter) ([]SessionMetadata, error)` - 列出工作階段 (可選篩選)
- `DeleteSession(sessionID string) error` - 永久刪除工作階段
- `GetLastSessionID(ctx context.Context) (*string, error)` - 獲取最近更新的工作階段 ID
- `GetState() ConnectionState` - 獲取連線狀態
- `Ping(message string) (*PingResponse, error)` - 偵測伺服器
- `GetForegroundSessionID(ctx context.Context) (*string, error)` - 獲取當前在 TUI 中顯示的工作階段 ID (僅限 TUI+伺服器模式)
- `SetForegroundSessionID(ctx context.Context, sessionID string) error` - 請求 TUI 顯示特定工作階段 (僅限 TUI+伺服器模式)
- `On(handler SessionLifecycleHandler) func()` - 訂閱所有生命週期事件；傳回取消訂閱函式
- `OnEventType(eventType SessionLifecycleEventType, handler SessionLifecycleHandler) func()` - 訂閱特定的生命週期事件類型

**工作階段生命週期事件：**

```go
// 訂閱所有生命週期事件
unsubscribe := client.On(func(event copilot.SessionLifecycleEvent) {
    fmt.Printf("工作階段 %s: %s\n", event.SessionID, event.Type)
})
defer unsubscribe()

// 訂閱特定的事件類型
unsubscribe := client.OnEventType(copilot.SessionLifecycleForeground, func(event copilot.SessionLifecycleEvent) {
    fmt.Printf("工作階段 %s 現在處於前景\n", event.SessionID)
})
```

事件類型：`SessionLifecycleCreated`, `SessionLifecycleDeleted`, `SessionLifecycleUpdated`, `SessionLifecycleForeground`, `SessionLifecycleBackground`

**ClientOptions:**

- `CLIPath` (string): CLI 執行檔路徑 (預設："copilot" 或 `COPILOT_CLI_PATH` 環境變數)
- `CLIUrl` (string): 現有 CLI 伺服器的 URL (例如 `"localhost:8080"`、`"http://127.0.0.1:9000"` 或僅為 `"8080"`)。提供後，用戶端將不會衍生 CLI 程序。
- `Cwd` (string): CLI 程序的目前工作目錄
- `Port` (int): TCP 模式的伺服器連接埠 (預設：0 表示隨機)
- `UseStdio` (bool): 使用 stdio 傳輸而非 TCP (預設：true)
- `LogLevel` (string): 記錄層級 (預設："info")
- `AutoStart` (\*bool): 首次使用時自動啟動伺服器 (預設：true)。使用 `Bool(false)` 停用。
- `AutoRestart` (\*bool): 當機時自動重新啟動 (預設：true)。使用 `Bool(false)` 停用。
- `Env` ([]string): CLI 程序的環境變數 (預設：繼承自目前程序)
- `GitHubToken` (string): 用於身分驗證的 GitHub 權杖。提供後，優先於其他驗證方法。
- `UseLoggedInUser` (\*bool): 是否使用已登入使用者進行身分驗證 (預設：true，但提供 `GitHubToken` 時為 false)。不能與 `CLIUrl` 一起使用。

**SessionConfig:**

- `Model` (string): 要使用的模型 ("gpt-5"、"claude-sonnet-4.5" 等)。**使用自訂提供者時為必填。**
- `ReasoningEffort` (string): 支援模型的推理努力層級 ("low", "medium", "high", "xhigh")。使用 `ListModels()` 檢查哪些模型支援此選項。
- `SessionID` (string): 自訂工作階段 ID
- `Tools` ([]Tool): 公開給 CLI 的自訂工具
- `SystemMessage` (\*SystemMessageConfig): 系統訊息設定
- `Provider` (\*ProviderConfig): 自訂 API 提供者設定 (BYOK)。請參閱 [自訂提供者](#custom-providers) 章節。
- `Streaming` (bool): 啟用串流增量事件
- `InfiniteSessions` (\*InfiniteSessionConfig): 自動內容壓縮設定
- `OnUserInputRequest` (UserInputHandler): 來自代理的使用者輸入請求處理常式 (啟用 ask_user 工具)。請參閱 [使用者輸入請求](#user-input-requests) 章節。
- `Hooks` (\*SessionHooks): 工作階段生命週期事件的 Hook 處理常式。請參閱 [工作階段 Hook](#session-hooks) 章節。

**ResumeSessionConfig:**

- `Tools` ([]Tool): 恢復時要公開的工具
- `ReasoningEffort` (string): 支援模型的推理努力層級
- `Provider` (\*ProviderConfig): 自訂 API 提供者設定 (BYOK)。請參閱 [自訂提供者](#custom-providers) 章節。
- `Streaming` (bool): 啟用串流增量事件

### Session

- `Send(ctx context.Context, options MessageOptions) (string, error)` - 發送訊息
- `On(handler SessionEventHandler) func()` - 訂閱事件 (傳回取消訂閱函式)
- `Abort(ctx context.Context) error` - 中止當前正在處理的訊息
- `GetMessages(ctx context.Context) ([]SessionEvent, error)` - 獲取訊息歷程記錄
- `Disconnect() error` - 中斷工作階段連線 (釋放記憶體資源，保留磁碟狀態)
- `Destroy() error` - *(已棄用)* 請改用 `Disconnect()`

### 輔助函式

- `Bool(v bool) *bool` - 用於為 `AutoStart`/`AutoRestart` 選項建立 bool 指標的輔助函式

## 影像支援

SDK 透過 `MessageOptions` 中的 `Attachments` 欄位支援影像附件。您可以透過提供影像檔案路徑來附加影像：

```go
_, err = session.Send(context.Background(), copilot.MessageOptions{
    Prompt: "這張影像中是什麼？",
    Attachments: []copilot.Attachment{
        {
            Type: "file",
            Path: "/path/to/image.jpg",
        },
    },
})
```

支援的影像格式包括 JPG、PNG、GIF 和其他常見影像類型。代理的 `view` 工具也可以直接從檔案系統讀取影像，因此您也可以提出如下問題：

```go
_, err = session.Send(context.Background(), copilot.MessageOptions{
    Prompt: "此目錄中最近的 jpg 描繪了什麼？",
})
```

### 工具

透過將工具附加到工作階段來向 Copilot 公開您自己的功能。

#### 使用 DefineTool (建議)

使用 `DefineTool` 進行具有自動 JSON 架構產生的類型安全工具：

```go
type LookupIssueParams struct {
    ID string `json:"id" jsonschema:"問題識別碼"`
}

lookupIssue := copilot.DefineTool("lookup_issue", "從我們的追蹤器獲取問題詳細資訊",
    func(params LookupIssueParams, inv copilot.ToolInvocation) (any, error) {
        // params 會自動從 LLM 的引數中解碼
        issue, err := fetchIssue(params.ID)
        if err != nil {
            return nil, err
        }
        return issue.Summary, nil
    })

session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    Tools: []copilot.Tool{lookupIssue},
})
```

#### 直接使用 Tool 結構

對於 JSON 架構的更多控制，請直接使用 `Tool` 結構：

```go
lookupIssue := copilot.Tool{
    Name:        "lookup_issue",
    Description: "從我們的追蹤器獲取問題詳細資訊",
    Parameters: map[string]any{
        "type": "object",
        "properties": map[string]any{
            "id": map[string]any{
                "type":        "string",
                "description": "問題識別碼",
            },
        },
        "required": []string{"id"},
    },
    Handler: func(invocation copilot.ToolInvocation) (copilot.ToolResult, error) {
        args := invocation.Arguments.(map[string]any)
        issue, err := fetchIssue(args["id"].(string))
        if err != nil {
            return copilot.ToolResult{}, err
        }
        return copilot.ToolResult{
            TextResultForLLM: issue.Summary,
            ResultType:       "success",
            SessionLog:       fmt.Sprintf("已獲取問題 %s", issue.ID),
        }, nil
    },
}

session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    Tools: []copilot.Tool{lookupIssue},
})
```

當模型選擇一個工具時，SDK 會自動執行您的處理常式 (與其他呼叫並行)，並使用處理常式的結果回應 CLI 的 `tool.call`。

#### 覆蓋內建工具

如果您註冊了一個與內建 CLI 工具同名的工具 (例如 `edit_file`、`read_file`)，除非您透過設定 `OverridesBuiltInTool = true` 明確加入，否則 SDK 將擲回錯誤。此旗標表示您打算使用自訂實作取代內建工具。

```go
editFile := copilot.DefineTool("edit_file", "具有專案特定驗證的自訂檔案編輯器",
    func(params EditFileParams, inv copilot.ToolInvocation) (any, error) {
        // 您的邏輯
    })
editFile.OverridesBuiltInTool = true
```

## 串流 (Streaming)

啟用串流以在產生助理回應區塊時接收它們：

```go
package main

import (
	"context"
    "fmt"
    "log"

    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    client := copilot.NewClient(nil)

    if err := client.Start(context.Background()); err != nil {
        log.Fatal(err)
    }
    defer client.Stop()

    session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
        Model:     "gpt-5",
        Streaming: true,
    })
    if err != nil {
        log.Fatal(err)
    }
    defer session.Disconnect()

    done := make(chan bool)

    session.On(func(event copilot.SessionEvent) {
        if event.Type == "assistant.message_delta" {
            // 串流訊息區塊 - 增量列印
            if event.Data.DeltaContent != nil {
                fmt.Print(*event.Data.DeltaContent)
            }
        } else if event.Type == "assistant.reasoning_delta" {
            // 串流推理區塊 (如果模型支援推理)
            if event.Data.DeltaContent != nil {
                fmt.Print(*event.Data.DeltaContent)
            }
        } else if event.Type == "assistant.message" {
            // 最終訊息 - 完整內容
            fmt.Println("\n--- 最終訊息 ---")
            if event.Data.Content != nil {
                fmt.Println(*event.Data.Content)
            }
        } else if event.Type == "assistant.reasoning" {
            // 最終推理內容 (如果模型支援推理)
            fmt.Println("--- 推理 ---")
            if event.Data.Content != nil {
                fmt.Println(*event.Data.Content)
            }
        }
        if event.Type == "session.idle" {
            close(done)
        }
    })

    _, err = session.Send(context.Background(), copilot.MessageOptions{
        Prompt: "給我講個短篇故事",
    })
    if err != nil {
        log.Fatal(err)
    }

    <-done
}
```

當 `Streaming: true` 時：

- 發送 `assistant.message_delta` 事件，其中 `DeltaContent` 包含增量文字
- 發送 `assistant.reasoning_delta` 事件，其中 `DeltaContent` 用於推理/思維鏈 (取決於模型)
- 累加 `DeltaContent` 值以逐步建立完整回應
- 最終的 `assistant.message` 和 `assistant.reasoning` 事件包含完整內容

注意：無論串流設定如何，始終會發送 `assistant.message` 和 `assistant.reasoning` (最終事件)。

## 無限工作階段 (Infinite Sessions)

預設情況下，工作階段使用 **無限工作階段**，它透過背景壓縮自動管理內容視窗限制，並將狀態持久化到工作區目錄。

```go
// 預設：啟用具有預設閾值的無限工作階段
session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
})

// 存取檢查點和檔案的工作區路徑
fmt.Println(session.WorkspacePath())
// => ~/.copilot/session-state/{sessionId}/

// 自訂閾值
session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    InfiniteSessions: &copilot.InfiniteSessionConfig{
        Enabled:                       copilot.Bool(true),
        BackgroundCompactionThreshold: copilot.Float64(0.80), // 在內容使用率達到 80% 時開始壓縮
        BufferExhaustionThreshold:     copilot.Float64(0.95), // 在達到 95% 時封鎖，直到壓縮完成
    },
})

// 停用無限工作階段
session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    InfiniteSessions: &copilot.InfiniteSessionConfig{
        Enabled: copilot.Bool(false),
    },
})
```

啟用時，工作階段會發出壓縮事件：

- `session.compaction_start` - 背景壓縮已開始
- `session.compaction_complete` - 壓縮已完成 (包括權杖計數)

## 自訂提供者

SDK 支援自訂的 OpenAI 相容 API 提供者 (BYOK - 自備金鑰)，包括像 Ollama 這樣的本地提供者。使用自訂提供者時，您必須明確指定 `Model`。

**ProviderConfig:**

- `Type` (string): 提供者類型 - "openai"、"azure" 或 "anthropic" (預設："openai")
- `BaseURL` (string): API 端點 URL (必填)
- `APIKey` (string): API 金鑰 (對於像 Ollama 這樣的本地提供者是選用的)
- `BearerToken` (string): 身分驗證的 Bearer 權杖 (優先於 APIKey)
- `WireApi` (string): OpenAI/Azure 的 API 格式 - "completions" 或 "responses" (預設："completions")
- `Azure.APIVersion` (string): Azure API 版本 (預設："2024-10-21")

**Ollama 範例：**

```go
session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "deepseek-coder-v2:16b", // 使用自訂提供者時必填
    Provider: &copilot.ProviderConfig{
        Type:    "openai",
        BaseURL: "http://localhost:11434/v1", // Ollama 端點
        // Ollama 不需要 APIKey
    },
})
```

**自訂 OpenAI 相容 API 範例：**

```go
session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-4",
    Provider: &copilot.ProviderConfig{
        Type:    "openai",
        BaseURL: "https://my-api.example.com/v1",
        APIKey:  os.Getenv("MY_API_KEY"),
    },
})
```

**Azure OpenAI 範例：**

```go
session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-4",
    Provider: &copilot.ProviderConfig{
        Type:    "azure",  // 對於 Azure 端點必須是 "azure"，而不是 "openai"
        BaseURL: "https://my-resource.openai.azure.com",  // 僅為主機，無路徑
        APIKey:  os.Getenv("AZURE_OPENAI_KEY"),
        Azure: &copilot.AzureProviderOptions{
            APIVersion: "2024-10-21",
        },
    },
})
```
> **重要注意事項：**
> - 使用自訂提供者時，`Model` 參數是 **必填的**。如果未指定模型，SDK 將傳回錯誤。
> - 對於 Azure OpenAI 端點 (`*.openai.azure.com`)，您 **必須** 使用 `Type: "azure"`，而不是 `Type: "openai"`。
> - `BaseURL` 應該只是主機 (例如 `https://my-resource.openai.azure.com`)。**不要** 在 URL 中包含 `/openai/v1` —— SDK 會自動處理路徑建構。

## 使用者輸入請求

透過提供 `OnUserInputRequest` 處理常式，讓代理能夠使用 `ask_user` 工具向使用者提問：

```go
session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    OnUserInputRequest: func(request copilot.UserInputRequest, invocation copilot.UserInputInvocation) (copilot.UserInputResponse, error) {
        // request.Question - 要問的問題
        // request.Choices - 選用的多選選項切片
        // request.AllowFreeform - 是否允許自由格式輸入 (預設：true)

        fmt.Printf("代理詢問：%s\n", request.Question)
        if len(request.Choices) > 0 {
            fmt.Printf("選項：%v\n", request.Choices)
        }

        // 傳回使用者的回應
        return copilot.UserInputResponse{
            Answer:      "使用者在此回答",
            WasFreeform: true, // 回答是否為自由格式 (非來自選項)
        }, nil
    },
})
```

## 工作階段 Hook

透過在 `Hooks` 設定中提供處理常式來連結工作階段生命週期事件：

```go
session, err := client.CreateSession(context.Background(), &copilot.SessionConfig{
    Model: "gpt-5",
    Hooks: &copilot.SessionHooks{
        // 在每次工具執行之前呼叫
        OnPreToolUse: func(input copilot.PreToolUseHookInput, invocation copilot.HookInvocation) (*copilot.PreToolUseHookOutput, error) {
            fmt.Printf("即將執行工具：%s\n", input.ToolName)
            // 傳回權限決策並選擇性地修改引數
            return &copilot.PreToolUseHookOutput{
                PermissionDecision: "allow", // "allow", "deny" 或 "ask"
                ModifiedArgs:       input.ToolArgs, // 選擇性地修改工具引數
                AdditionalContext:  "模型的額外內容",
            }, nil
        },

        // 在每次工具執行之後呼叫
        OnPostToolUse: func(input copilot.PostToolUseHookInput, invocation copilot.HookInvocation) (*copilot.PostToolUseHookOutput, error) {
            fmt.Printf("工具 %s 已完成\n", input.ToolName)
            return &copilot.PostToolUseHookOutput{
                AdditionalContext: "執行後筆記",
            }, nil
        },

        // 當使用者提交提示時呼叫
        OnUserPromptSubmitted: func(input copilot.UserPromptSubmittedHookInput, invocation copilot.HookInvocation) (*copilot.UserPromptSubmittedHookOutput, error) {
            fmt.Printf("使用者提示：%s\n", input.Prompt)
            return &copilot.UserPromptSubmittedHookOutput{
                ModifiedPrompt: input.Prompt, // 選擇性地修改提示
            }, nil
        },

        // 當工作階段開始時呼叫
        OnSessionStart: func(input copilot.SessionStartHookInput, invocation copilot.HookInvocation) (*copilot.SessionStartHookOutput, error) {
            fmt.Printf("工作階段從 %s 開始\n", input.Source) // "startup", "resume", "new"
            return &copilot.SessionStartHookOutput{
                AdditionalContext: "工作階段初始化內容",
            }, nil
        },

        // 當工作階段結束時呼叫
        OnSessionEnd: func(input copilot.SessionEndHookInput, invocation copilot.HookInvocation) (*copilot.SessionEndHookOutput, error) {
            fmt.Printf("工作階段結束：%s\n", input.Reason)
            return nil, nil
        },

        // 當發生錯誤時呼叫
        OnErrorOccurred: func(input copilot.ErrorOccurredHookInput, invocation copilot.HookInvocation) (*copilot.ErrorOccurredHookOutput, error) {
            fmt.Printf("在 %s 中發生錯誤：%s\n", input.ErrorContext, input.Error)
            return &copilot.ErrorOccurredHookOutput{
                ErrorHandling: "retry", // "retry", "skip" 或 "abort"
            }, nil
        },
    },
})
```

**可用的 Hook：**

- `OnPreToolUse` - 在執行前攔截工具呼叫。可以允許/拒絕或修改引數。
- `OnPostToolUse` - 在執行後處理工具結果。可以修改結果或新增內容。
- `OnUserPromptSubmitted` - 攔截使用者提示。可以在處理前修改提示。
- `OnSessionStart` - 在工作階段開始或恢復時執行邏輯。
- `OnSessionEnd` - 工作階段結束時的清理或記錄。
- `OnErrorOccurred` - 使用重試/跳過/中止策略處理錯誤。

## 傳輸模式

### stdio (預設)

透過 stdin/stdout 管道與 CLI 通訊。建議用於大多數案例。

```go
client := copilot.NewClient(nil) // 預設使用 stdio
```

### TCP

透過 TCP 通訊端與 CLI 通訊。對於分散式場景很有用。

## 環境變數

- `COPILOT_CLI_PATH` - Copilot CLI 執行檔路徑

## 授權

MIT
