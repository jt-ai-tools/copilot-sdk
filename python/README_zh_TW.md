# Copilot Python SDK

用於透過 JSON-RPC 以程式化方式控制 GitHub Copilot CLI 的 Python SDK。

> **注意：** 此 SDK 處於技術預覽階段，可能會發生破壞性變更。

## 安裝

```bash
pip install -e ".[dev]"
# 或
uv pip install -e ".[dev]"
```

## 執行範例

嘗試互動式聊天範例 (從儲存庫根目錄)：

```bash
cd python/samples
python chat.py
```

## 快速入門

```python
import asyncio
from copilot import CopilotClient

async def main():
    # 建立並啟動用戶端
    client = CopilotClient()
    await client.start()

    # 建立一個工作階段
    session = await client.create_session({"model": "gpt-5"})

    # 使用 session.idle 事件等待回應
    done = asyncio.Event()

    def on_event(event):
        if event.type.value == "assistant.message":
            print(event.data.content)
        elif event.type.value == "session.idle":
            done.set()

    session.on(on_event)

    # 發送訊息並等待完成
    await session.send({"prompt": "2+2 等於多少？"})
    await done.wait()

    # 清理
    await session.disconnect()
    await client.stop()

asyncio.run(main())
```

工作階段還支援 `async with` 內容管理員模式以進行自動清理：

```python
async with await client.create_session({"model": "gpt-5"}) as session:
    await session.send({"prompt": "2+2 等於多少？"})
    # 離開區塊時，工作階段會自動中斷連接
```

## 功能

- ✅ 完整的 JSON-RPC 協定支援
- ✅ stdio 和 TCP 傳輸
- ✅ 即時串流事件
- ✅ 具備 `get_messages()` 的工作階段歷程記錄
- ✅ 全程類型提示
- ✅ 原生 Async/await 支援

## API 參考

### CopilotClient

```python
client = CopilotClient({
    "cli_path": "copilot",  # 選用：CLI 執行檔路徑
    "cli_url": None,        # 選用：現有伺服器的 URL (例如 "localhost:8080")
    "log_level": "info",    # 選用：記錄層級 (預設："info")
    "auto_start": True,     # 選用：自動啟動伺服器 (預設：True)
    "auto_restart": True,   # 選用：當機時自動重新啟動 (預設：True)
})
await client.start()

session = await client.create_session({"model": "gpt-5"})

def on_event(event):
    print(f"事件：{event['type']}")

session.on(on_event)
await session.send({"prompt": "哈囉！"})

# ... 等待事件 ...

await session.disconnect()
await client.stop()
```

**CopilotClient 選項：**

- `cli_path` (str): CLI 執行檔路徑 (預設："copilot" 或 `COPILOT_CLI_PATH` 環境變數)
- `cli_url` (str): 現有 CLI 伺服器的 URL (例如 `"localhost:8080"`、`"http://127.0.0.1:9000"` 或僅為 `"8080"`)。提供後，用戶端將不會衍生 CLI 程序。
- `cwd` (str): CLI 程序的目前工作目錄
- `port` (int): TCP 模式的伺服器連接埠 (預設：0 表示隨機)
- `use_stdio` (bool): 使用 stdio 傳輸而非 TCP (預設：True)
- `log_level` (str): 記錄層級 (預設："info")
- `auto_start` (bool): 首次使用時自動啟動伺服器 (預設：True)
- `auto_restart` (bool): 當機時自動重新啟動 (預設：True)
- `github_token` (str): 用於身分驗證的 GitHub 權杖。提供後，優先於其他驗證方法。
- `use_logged_in_user` (bool): 是否使用已登入使用者進行身分驗證 (預設：True，但提供 `github_token` 時為 False)。不能與 `cli_url` 一起使用。

**SessionConfig 選項 (用於 `create_session`)：**

- `model` (str): 要使用的模型 ("gpt-5"、"claude-sonnet-4.5" 等)。**使用自訂提供者時為必填。**
- `reasoning_effort` (str): 支援模型的推理努力層級 ("low", "medium", "high", "xhigh")。使用 `list_models()` 檢查哪些模型支援此選項。
- `session_id` (str): 自訂工作階段 ID
- `tools` (list): 公開給 CLI 的自訂工具
- `system_message` (dict): 系統訊息設定
- `streaming` (bool): 啟用串流增量事件
- `provider` (dict): 自訂 API 提供者設定 (BYOK)。請參閱 [自訂提供者](#custom-providers) 章節。
- `infinite_sessions` (dict): 自動內容壓縮設定
- `on_user_input_request` (callable): 來自代理的使用者輸入請求處理常式 (啟用 ask_user 工具)。請參閱 [使用者輸入請求](#user-input-requests) 章節。
- `hooks` (dict): 工作階段生命週期事件的 Hook 處理常式。請參閱 [工作階段 Hook](#session-hooks) 章節。

**工作階段生命週期方法：**

```python
# 獲取當前在 TUI 中顯示的工作階段 ID (僅限 TUI+伺服器模式)
session_id = await client.get_foreground_session_id()

# 請求 TUI 顯示特定工作階段 (僅限 TUI+伺服器模式)
await client.set_foreground_session_id("session-123")

# 訂閱所有生命週期事件
def on_lifecycle(event):
    print(f"{event.type}: {event.sessionId}")

unsubscribe = client.on(on_lifecycle)

# 訂閱特定的事件類型
unsubscribe = client.on("session.foreground", lambda e: print(f"前景：{e.sessionId}"))

# 稍後停止接收事件：
unsubscribe()
```

**生命週期事件類型：**
- `session.created` - 建立了一個新的工作階段
- `session.deleted` - 刪除了一個工作階段
- `session.updated` - 更新了一個工作階段
- `session.foreground` - 工作階段成為 TUI 中的前景工作階段
- `session.background` - 工作階段不再是前景工作階段

### 工具

使用 `@define_tool` 裝飾器和 Pydantic 模型定義具有自動 JSON 架構產生的工具：

```python
from pydantic import BaseModel, Field
from copilot import CopilotClient, define_tool

class LookupIssueParams(BaseModel):
    id: str = Field(description="問題識別碼")

@define_tool(description="從我們的追蹤器獲取問題詳細資訊")
async def lookup_issue(params: LookupIssueParams) -> str:
    issue = await fetch_issue(params.id)
    return issue.summary

session = await client.create_session({
    "model": "gpt-5",
    "tools": [lookup_issue],
})
```

> **注意：** 使用 `from __future__ import annotations` 時，請在模組層級 (而非函式內部) 定義 Pydantic 模型。

**低階 API (不使用 Pydantic)：**

對於偏好手動架構定義的使用者：

```python
from copilot import CopilotClient, Tool

async def lookup_issue(invocation):
    issue_id = invocation["arguments"]["id"]
    issue = await fetch_issue(issue_id)
    return {
        "textResultForLlm": issue.summary,
        "resultType": "success",
        "sessionLog": f"已獲取問題 {issue_id}",
    }

session = await client.create_session({
    "model": "gpt-5",
    "tools": [
        Tool(
            name="lookup_issue",
            description="從我們的追蹤器獲取問題詳細資訊",
            parameters={
                "type": "object",
                "properties": {
                    "id": {"type": "string", "description": "問題識別碼"},
                },
                "required": ["id"],
            },
            handler=lookup_issue,
        )
    ],
})
```

SDK 會自動處理 `tool.call`，執行您的處理常式 (同步或非同步)，並在工具完成時傳回最終結果。

#### 覆蓋內建工具

如果您註冊了一個與內建 CLI 工具同名的工具 (例如 `edit_file`、`read_file`)，除非您透過設定 `overrides_built_in_tool=True` 明確加入，否則 SDK 將擲回錯誤。此旗標表示您打算使用自訂實作取代內建工具。

```python
class EditFileParams(BaseModel):
    path: str = Field(description="檔案路徑")
    content: str = Field(description="新的檔案內容")

@define_tool(name="edit_file", description="具有專案特定驗證的自訂檔案編輯器", overrides_built_in_tool=True)
async def edit_file(params: EditFileParams) -> str:
    # 您的邏輯
```

## 影像支援

SDK 透過 `attachments` 參數支援影像附件。您可以透過提供影像檔案路徑來附加影像：

```python
await session.send({
    "prompt": "這張影像中是什麼？",
    "attachments": [
        {
            "type": "file",
            "path": "/path/to/image.jpg",
        }
    ]
})
```

支援的影像格式包括 JPG、PNG、GIF 和其他常見影像類型。代理的 `view` 工具也可以直接從檔案系統讀取影像，因此您也可以提出如下問題：

```python
await session.send({"prompt": "此目錄中最近的 jpg 描繪了什麼？"})
```

## 串流 (Streaming)

啟用串流以在產生助理回應區塊時接收它們：

```python
import asyncio
from copilot import CopilotClient

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-5",
        "streaming": True
    })

    # 使用 asyncio.Event 等待完成
    done = asyncio.Event()

    def on_event(event):
        if event.type.value == "assistant.message_delta":
            # 串流訊息區塊 - 增量列印
            delta = event.data.delta_content or ""
            print(delta, end="", flush=True)
        elif event.type.value == "assistant.reasoning_delta":
            # 串流推理區塊 (如果模型支援推理)
            delta = event.data.delta_content or ""
            print(delta, end="", flush=True)
        elif event.type.value == "assistant.message":
            # 最終訊息 - 完整內容
            print("\n--- 最終訊息 ---")
            print(event.data.content)
        elif event.type.value == "assistant.reasoning":
            # 最終推理內容 (如果模型支援推理)
            print("--- 推理 ---")
            print(event.data.content)
        elif event.type.value == "session.idle":
            # 工作階段處理完成
            done.set()

    session.on(on_event)
    await session.send({"prompt": "給我講個短篇故事"})
    await done.wait()  # 等待串流完成

    await session.disconnect()
    await client.stop()

asyncio.run(main())
```

當 `streaming=True` 時：

- 發送 `assistant.message_delta` 事件，其中 `delta_content` 包含增量文字
- 發送 `assistant.reasoning_delta` 事件，其中 `delta_content` 用於推理/思維鏈 (取決於模型)
- 累加 `delta_content` 值以逐步建立完整回應
- 無論串流設定如何，始終會發送最終的 `assistant.message` 和 `assistant.reasoning` 事件

注意：`assistant.message` 和 `assistant.reasoning` (最終事件) 無論串流設定為何都會發送。

## 無限工作階段 (Infinite Sessions)

預設情況下，工作階段使用 **無限工作階段**，它透過背景壓縮自動管理內容視窗限制，並將狀態持久化到工作區目錄。

```python
# 預設：啟用具有預設閾值的無限工作階段
session = await client.create_session({"model": "gpt-5"})

# 存取檢查點和檔案的工作區路徑
print(session.workspace_path)
# => ~/.copilot/session-state/{session_id}/

# 自訂閾值
session = await client.create_session({
    "model": "gpt-5",
    "infinite_sessions": {
        "enabled": True,
        "background_compaction_threshold": 0.80,  # 在內容使用率達到 80% 時開始壓縮
        "buffer_exhaustion_threshold": 0.95,  # 在達到 95% 時封鎖，直到壓縮完成
    },
})

# 停用無限工作階段
session = await client.create_session({
    "model": "gpt-5",
    "infinite_sessions": {"enabled": False},
})
```

啟用時，工作階段會發出壓縮事件：

- `session.compaction_start` - 背景壓縮已開始
- `session.compaction_complete` - 壓縮已完成 (包括權杖計數)

## 自訂提供者

SDK 支援自訂的 OpenAI 相容 API 提供者 (BYOK - 自備金鑰)，包括像 Ollama 這樣的本地提供者。使用自訂提供者時，您必須明確指定 `model`。

**ProviderConfig 欄位：**

- `type` (str): 提供者類型 - `"openai"`、`"azure"` 或 `"anthropic"` (預設：`"openai"`)
- `base_url` (str): API 端點 URL (必填)
- `api_key` (str): API 金鑰 (對於像 Ollama 這樣的本地提供者是選用的)
- `bearer_token` (str): 身分驗證的 Bearer 權杖 (優先於 `api_key`)
- `wire_api` (str): OpenAI/Azure 的 API 格式 - `"completions"` 或 `"responses"` (預設：`"completions"`)
- `azure` (dict): 具有 `api_version` 的 Azure 特定選項 (預設：`"2024-10-21"`)

**Ollama 範例：**

```python
session = await client.create_session({
    "model": "deepseek-coder-v2:16b",  # 使用自訂提供者時必填
    "provider": {
        "type": "openai",
        "base_url": "http://localhost:11434/v1",  # Ollama 端點
        # Ollama 不需要 api_key
    },
})

await session.send({"prompt": "哈囉！"})
```

**自訂 OpenAI 相容 API 範例：**

```python
import os

session = await client.create_session({
    "model": "gpt-4",
    "provider": {
        "type": "openai",
        "base_url": "https://my-api.example.com/v1",
        "api_key": os.environ["MY_API_KEY"],
    },
})
```

**Azure OpenAI 範例：**

```python
import os

session = await client.create_session({
    "model": "gpt-4",
    "provider": {
        "type": "azure",  # 對於 Azure 端點必須是 "azure"，而不是 "openai"
        "base_url": "https://my-resource.openai.azure.com",  # 僅為主機，無路徑
        "api_key": os.environ["AZURE_OPENAI_KEY"],
        "azure": {
            "api_version": "2024-10-21",
        },
    },
})
```

> **重要注意事項：**
> - 使用自訂提供者時，`model` 參數是 **必填的**。如果未指定模型，SDK 將擲回錯誤。
> - 對於 Azure OpenAI 端點 (`*.openai.azure.com`)，您 **必須** 使用 `type: "azure"`，而不是 `type: "openai"`。
> - `base_url` 應該只是主機 (例如 `https://my-resource.openai.azure.com`)。**不要** 在 URL 中包含 `/openai/v1` —— SDK 會自動處理路徑建構。

## 使用者輸入請求

透過提供 `on_user_input_request` 處理常式，讓代理能夠使用 `ask_user` 工具向使用者提問：

```python
async def handle_user_input(request, invocation):
    # request["question"] - 要問的問題
    # request.get("choices") - 選用的多選選項列表
    # request.get("allowFreeform", True) - 是否允許自由格式輸入

    print(f"代理詢問：{request['question']}")
    if request.get("choices"):
        print(f"選項：{', '.join(request['choices'])}")

    # 傳回使用者的回應
    return {
        "answer": "使用者在此回答",
        "wasFreeform": True,  # 回答是否為自由格式 (非來自選項)
    }

session = await client.create_session({
    "model": "gpt-5",
    "on_user_input_request": handle_user_input,
})
```

## 工作階段 Hook

透過在 `hooks` 設定中提供處理常式來連結工作階段生命週期事件：

```python
async def on_pre_tool_use(input, invocation):
    print(f"即將執行工具：{input['toolName']}")
    # 傳回權限決策並選擇性地修改引數
    return {
        "permissionDecision": "allow",  # "allow", "deny" 或 "ask"
        "modifiedArgs": input.get("toolArgs"),  # 選擇性地修改工具引數
        "additionalContext": "模型的額外內容",
    }

async def on_post_tool_use(input, invocation):
    print(f"工具 {input['toolName']} 已完成")
    return {
        "additionalContext": "執行後筆記",
    }

async def on_user_prompt_submitted(input, invocation):
    print(f"使用者提示：{input['prompt']}")
    return {
        "modifiedPrompt": input["prompt"],  # 選擇性地修改提示
    }

async def on_session_start(input, invocation):
    print(f"工作階段從 {input['source']} 開始")  # "startup", "resume", "new"
    return {
        "additionalContext": "工作階段初始化內容",
    }

async def on_session_end(input, invocation):
    print(f"工作階段結束：{input['reason']}")

async def on_error_occurred(input, invocation):
    print(f"在 {input['errorContext']} 中發生錯誤：{input['error']}")
    return {
        "errorHandling": "retry",  # "retry", "skip" 或 "abort"
    }

session = await client.create_session({
    "model": "gpt-5",
    "hooks": {
        "on_pre_tool_use": on_pre_tool_use,
        "on_post_tool_use": on_post_tool_use,
        "on_user_prompt_submitted": on_user_prompt_submitted,
        "on_session_start": on_session_start,
        "on_session_end": on_session_end,
        "on_error_occurred": on_error_occurred,
    },
})
```

**可用的 Hook：**

- `on_pre_tool_use` - 在執行前攔截工具呼叫。可以允許/拒絕或修改引數。
- `on_post_tool_use` - 在執行後處理工具結果。可以修改結果或新增內容。
- `on_user_prompt_submitted` - 攔截使用者提示。可以在處理前修改提示。
- `on_session_start` - 在工作階段開始或恢復時執行邏輯。
- `on_session_end` - 工作階段結束時的清理或記錄。
- `on_error_occurred` - 使用重試/跳過/中止策略處理錯誤。

## 需求

- Python 3.11+
- 已安裝 GitHub Copilot CLI 且可存取
