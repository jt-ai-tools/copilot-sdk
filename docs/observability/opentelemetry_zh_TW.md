# Copilot SDK 的 OpenTelemetry 檢測 (Instrumentation)

本指南介紹如何使用 GenAI 語意慣例 (semantic conventions) 為您的 Copilot SDK 應用程式新增 OpenTelemetry 追蹤 (tracing)。

## 概覽

Copilot SDK 在處理代理程式請求時會發出工作階段事件。您可以檢測您的應用程式，根據 [OpenTelemetry GenAI 語意慣例 v1.34.0](https://opentelemetry.io/docs/specs/semconv/gen-ai/)，將這些事件轉換為 OpenTelemetry 的 Span 與屬性。

## 安裝

```bash
pip install opentelemetry-sdk opentelemetry-api
```

用於匯出至觀測後端：

```bash
# 控制台輸出
pip install opentelemetry-sdk

# Azure Monitor
pip install azure-monitor-opentelemetry

# OTLP (Jaeger, Prometheus 等)
pip install opentelemetry-exporter-otlp
```

## 基本設定

### 1. 初始化 OpenTelemetry

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor, ConsoleSpanExporter

# 設定 Tracer Provider
tracer_provider = TracerProvider()
trace.set_tracer_provider(tracer_provider)

# 新增 Exporter (以控制台為例)
span_exporter = ConsoleSpanExporter()
tracer_provider.add_span_processor(SimpleSpanProcessor(span_exporter))

# 獲取 Tracer
tracer = trace.get_tracer(__name__)
```

### 2. 在代理程式操作周圍建立 Span

```python
from copilot import CopilotClient, PermissionHandler
from copilot.generated.session_events import SessionEventType
from opentelemetry import trace, context
from opentelemetry.trace import SpanKind

# 初始化用戶端並啟動 CLI 伺服器
client = CopilotClient()
await client.start()

tracer = trace.get_tracer(__name__)

# 為代理程式調用建立 Span
span_attrs = {
    "gen_ai.operation.name": "invoke_agent",
    "gen_ai.provider.name": "github.copilot",
    "gen_ai.agent.name": "my-agent",
    "gen_ai.request.model": "gpt-5",
}

span = tracer.start_span(
    name="invoke_agent my-agent",
    kind=SpanKind.CLIENT,
    attributes=span_attrs
)
token = context.attach(trace.set_span_in_context(span))

try:
    # 建立工作階段 (模型是在此處設定，而非在用戶端上)
    session = await client.create_session({
        "model": "gpt-5",
        "on_permission_request": PermissionHandler.approve_all,
    })

    # 透過回呼訂閱事件
    def handle_event(event):
        if event.type == SessionEventType.ASSISTANT_USAGE:
            if event.data.model:
                span.set_attribute("gen_ai.response.model", event.data.model)

    unsubscribe = session.on(handle_event)

    # 發送訊息 (傳回訊息 ID)
    await session.send({"prompt": "Hello, world!"})

    # 或發送並等待工作階段進入閒置狀態
    response = await session.send_and_wait({"prompt": "Hello, world!"})
finally:
    context.detach(token)
    span.end()
    await client.stop()
```

## Copilot SDK 事件至 GenAI 屬性映射

Copilot SDK 在代理程式執行期間會發出 `SessionEventType` 事件。請使用 `session.on(handler)` 訂閱這些事件，該方法會傳回一個取消訂閱的函數。以下是如何將這些事件映射至 GenAI 語意慣例屬性：

### 核心工作階段事件

| SessionEventType | GenAI 屬性 | 描述 |
|------------------|------------------|-------------|
| `SESSION_START` | - | 工作階段初始化 (標記 Span 開始) |
| `SESSION_IDLE` | - | 工作階段完成 (標記 Span 結束) |
| `SESSION_ERROR` | `error.type`, `error.message` | 發生錯誤 |

### 助手 (Assistant) 事件

| SessionEventType | GenAI 屬性 | 描述 |
|------------------|------------------|-------------|
| `ASSISTANT_TURN_START` | - | 助手開始處理 |
| `ASSISTANT_TURN_END` | - | 助手結束處理 |
| `ASSISTANT_MESSAGE` | `gen_ai.output.messages` (事件) | 助手最終訊息，包含完整內容 |
| `ASSISTANT_MESSAGE_DELTA` | - | 串流訊息片段 (選用追蹤) |
| `ASSISTANT_USAGE` | `gen_ai.usage.input_tokens`<br>`gen_ai.usage.output_tokens`<br>`gen_ai.response.model` | 權杖使用量與模型資訊 |
| `ASSISTANT_REASONING` | - | 推理內容 (選用追蹤) |
| `ASSISTANT_INTENT` | - | 助手的理解意圖 |

### 工具執行事件

| SessionEventType | GenAI 屬性 / Span | 描述 |
|------------------|-------------------------|-------------|
| `TOOL_EXECUTION_START` | 建立子 Span：<br>- `gen_ai.tool.name`<br>- `gen_ai.tool.call.id`<br>- `gen_ai.operation.name`: `execute_tool`<br>- `gen_ai.tool.call.arguments` (選擇性加入) | 工具執行開始 |
| `TOOL_EXECUTION_COMPLETE` | 在子 Span 上：<br>- `gen_ai.tool.call.result` (選擇性加入)<br>- `error.type` (若失敗)<br>結束子 Span | 工具執行結束 |
| `TOOL_EXECUTION_PARTIAL_RESULT` | - | 串流工具結果 |

### 模型與上下文事件

| SessionEventType | GenAI 屬性 | 描述 |
|------------------|------------------|-------------|
| `SESSION_MODEL_CHANGE` | `gen_ai.request.model` | 工作階段中模型發生變更 |
| `SESSION_CONTEXT_CHANGED` | - | 上下文視窗已修改 |
| `SESSION_TRUNCATION` | - | 上下文已截斷 |

## 詳細事件映射範例

### ASSISTANT_USAGE 事件

當您收到 `ASSISTANT_USAGE` 事件時，提取權杖使用量：

```python
from copilot.generated.session_events import SessionEventType

def handle_usage(event):
    if event.type == SessionEventType.ASSISTANT_USAGE:
        data = event.data
        if data.model:
            span.set_attribute("gen_ai.response.model", data.model)
        if data.input_tokens is not None:
            span.set_attribute("gen_ai.usage.input_tokens", int(data.input_tokens))
        if data.output_tokens is not None:
            span.set_attribute("gen_ai.usage.output_tokens", int(data.output_tokens))

unsubscribe = session.on(handle_usage)
await session.send({"prompt": "Hello"})
```

**事件資料結構：**
<!-- docs-validate: hidden -->
```python
from dataclasses import dataclass

@dataclass
class Usage:
    input_tokens: float
    output_tokens: float
    cache_read_tokens: float
    cache_write_tokens: float
```
<!-- /docs-validate: hidden -->
```python
@dataclass
class Usage:
    input_tokens: float
    output_tokens: float
    cache_read_tokens: float
    cache_write_tokens: float
```

**映射至 GenAI 屬性：**
- `input_tokens` → `gen_ai.usage.input_tokens`
- `output_tokens` → `gen_ai.usage.output_tokens`
- 回應模型 → `gen_ai.response.model`

### TOOL_EXECUTION_START / COMPLETE 事件

為每次工具執行建立子 Span：

```python
from opentelemetry.trace import SpanKind
import json

# 用於追蹤使用中工具 Span 的字典
tool_spans = {}

def handle_tool_events(event):
    data = event.data

    if event.type == SessionEventType.TOOL_EXECUTION_START and data:
        call_id = data.tool_call_id or str(uuid.uuid4())
        tool_name = data.tool_name or "unknown"

        tool_attrs = {
            "gen_ai.tool.name": tool_name,
            "gen_ai.operation.name": "execute_tool",
        }

        if call_id:
            tool_attrs["gen_ai.tool.call.id"] = call_id

        # 選用：包含工具參數 (可能包含敏感資料)
        if data.arguments is not None:
            try:
                tool_attrs["gen_ai.tool.call.arguments"] = json.dumps(data.arguments)
            except Exception:
                tool_attrs["gen_ai.tool.call.arguments"] = str(data.arguments)

        tool_span = tracer.start_span(
            name=f"execute_tool {tool_name}",
            kind=SpanKind.CLIENT,
            attributes=tool_attrs
        )
        tool_token = context.attach(trace.set_span_in_context(tool_span))
        tool_spans[call_id] = (tool_span, tool_token)

    elif event.type == SessionEventType.TOOL_EXECUTION_COMPLETE and data:
        call_id = data.tool_call_id
        entry = tool_spans.pop(call_id, None) if call_id else None

        if entry:
            tool_span, tool_token = entry

            # 選用：包含工具結果 (可能包含敏感資料)
            if data.result is not None:
                try:
                    result_str = json.dumps(data.result)
                except Exception:
                    result_str = str(data.result)
                # 截斷至 512 字元以避免 Span 過大
                tool_span.set_attribute("gen_ai.tool.call.result", result_str[:512])

            # 若工具失敗，標記為錯誤
            if hasattr(data, "success") and data.success is False:
                tool_span.set_attribute("error.type", "tool_error")

            context.detach(tool_token)
            tool_span.end()

unsubscribe = session.on(handle_tool_events)
await session.send({"prompt": "What's the weather?"})
```

**工具事件資料：**
- `tool_call_id` → `gen_ai.tool.call.id`
- `tool_name` → `gen_ai.tool.name`
- `arguments` → `gen_ai.tool.call.arguments` (選擇性加入)
- `result` → `gen_ai.tool.call.result` (選擇性加入)

### ASSISTANT_MESSAGE 事件

將最終訊息擷取為 Span 事件：

```python
def handle_message(event):
    if event.type == SessionEventType.ASSISTANT_MESSAGE and event.data:
        if event.data.content:
            # 新增為 Span 事件 (選擇性加入以記錄內容)
            span.add_event(
                "gen_ai.output.messages",
                attributes={
                    "gen_ai.event.content": json.dumps({
                        "role": "assistant",
                        "content": event.data.content
                    })
                }
            )

unsubscribe = session.on(handle_message)
await session.send({"prompt": "Tell me a joke"})
```

## 完整範例

```python
import asyncio
import json
import uuid
from copilot import CopilotClient, PermissionHandler
from copilot.generated.session_events import SessionEventType
from opentelemetry import trace, context
from opentelemetry.trace import SpanKind
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor, ConsoleSpanExporter

# 設定 OpenTelemetry
tracer_provider = TracerProvider()
trace.set_tracer_provider(tracer_provider)
tracer_provider.add_span_processor(SimpleSpanProcessor(ConsoleSpanExporter()))
tracer = trace.get_tracer(__name__)

async def invoke_agent(prompt: str):
    """使用完整的 OpenTelemetry 檢測調用代理程式。"""

    # 建立主 Span
    span_attrs = {
        "gen_ai.operation.name": "invoke_agent",
        "gen_ai.provider.name": "github.copilot",
        "gen_ai.agent.name": "example-agent",
        "gen_ai.request.model": "gpt-5",
    }

    span = tracer.start_span(
        name="invoke_agent example-agent",
        kind=SpanKind.CLIENT,
        attributes=span_attrs
    )
    token = context.attach(trace.set_span_in_context(span))
    tool_spans = {}

    try:
        client = CopilotClient()
        await client.start()

        session = await client.create_session({
            "model": "gpt-5",
            "on_permission_request": PermissionHandler.approve_all,
        })

        # 透過回呼訂閱事件
        def handle_event(event):
            data = event.data

            # 處理使用量事件
            if event.type == SessionEventType.ASSISTANT_USAGE and data:
                if data.model:
                    span.set_attribute("gen_ai.response.model", data.model)
                if data.input_tokens is not None:
                    span.set_attribute("gen_ai.usage.input_tokens", int(data.input_tokens))
                if data.output_tokens is not None:
                    span.set_attribute("gen_ai.usage.output_tokens", int(data.output_tokens))

            # 處理工具執行
            elif event.type == SessionEventType.TOOL_EXECUTION_START and data:
                call_id = data.tool_call_id or str(uuid.uuid4())
                tool_name = data.tool_name or "unknown"

                tool_attrs = {
                    "gen_ai.tool.name": tool_name,
                    "gen_ai.operation.name": "execute_tool",
                    "gen_ai.tool.call.id": call_id,
                }

                tool_span = tracer.start_span(
                    name=f"execute_tool {tool_name}",
                    kind=SpanKind.CLIENT,
                    attributes=tool_attrs
                )
                tool_token = context.attach(trace.set_span_in_context(tool_span))
                tool_spans[call_id] = (tool_span, tool_token)

            elif event.type == SessionEventType.TOOL_EXECUTION_COMPLETE and data:
                call_id = data.tool_call_id
                entry = tool_spans.pop(call_id, None) if call_id else None
                if entry:
                    tool_span, tool_token = entry
                    context.detach(tool_token)
                    tool_span.end()

            # 擷取最終訊息
            elif event.type == SessionEventType.ASSISTANT_MESSAGE and data:
                if data.content:
                    print(f"Assistant: {data.content}")

        unsubscribe = session.on(handle_event)

        # 發送訊息並等待完成
        response = await session.send_and_wait({"prompt": prompt})

        span.set_attribute("gen_ai.response.finish_reasons", ["stop"])
        unsubscribe()

    except Exception as e:
        span.set_attribute("error.type", type(e).__name__)
        raise
    finally:
        # 清理任何未關閉的工具 Span
        for call_id, (tool_span, tool_token) in tool_spans.items():
            tool_span.set_attribute("error.type", "stream_aborted")
            context.detach(tool_token)
            tool_span.end()

        context.detach(token)
        span.end()
        await client.stop()

# 執行
asyncio.run(invoke_agent("What's 2+2?"))
```

## 必要 Span 屬性

根據 OpenTelemetry GenAI 語意慣例，代理程式調用 Span **必須** 具備以下屬性：

| 屬性 | 描述 | 範例 |
|-----------|-------------|---------|
| `gen_ai.operation.name` | 操作類型 | `invoke_agent`, `chat`, `execute_tool` |
| `gen_ai.provider.name` | 提供者識別碼 | `github.copilot` |
| `gen_ai.request.model` | 用於請求的模型 | `gpt-5`, `gpt-4.1` |

## 推薦 Span 屬性

以下屬性強烈推薦使用，以獲得更好的觀測能力：

| 屬性 | 描述 |
|-----------|-------------|
| `gen_ai.agent.id` | 唯一的代理程式識別碼 |
| `gen_ai.agent.name` | 易於理解的代理程式名稱 |
| `gen_ai.response.model` | 回應中實際使用的模型 |
| `gen_ai.usage.input_tokens` | 消耗的輸入權杖數 |
| `gen_ai.usage.output_tokens` | 產生的輸出權杖數 |
| `gen_ai.response.finish_reasons` | 完成原因 (例如：`["stop"]`) |

## 內容記錄

記錄訊息內容與工具參數/結果是 **選用** 的，且應為選擇性加入 (opt-in)，因為其中可能包含敏感資料。

### 環境變數控制

```bash
# 啟用內容記錄
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true
```

### 在執行時期檢查

<!-- docs-validate: hidden -->
```python
import os
from typing import Any

span: Any = None
event: Any = None

def should_record_content():
    return os.getenv("OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", "false").lower() == "true"

if should_record_content() and event.data.content:
    span.add_event("gen_ai.output.messages", ...)
```
<!-- /docs-validate: hidden -->
```python
import os

def should_record_content():
    return os.getenv("OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", "false").lower() == "true"

# 僅在啟用時新增內容
if should_record_content() and event.data.content:
    span.add_event("gen_ai.output.messages", ...)
```

## MCP (Model Context Protocol) 工具慣例

對於基於 MCP 的工具，請遵循 [OpenTelemetry MCP 語意慣例](https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/) 新增這些額外屬性：

<!-- docs-validate: hidden -->
```python
from typing import Any

data: Any = None
session: Any = None

tool_attrs = {
    "mcp.method.name": "tools/call",
    "mcp.server.name": data.mcp_server_name,
    "mcp.session.id": session.session_id,
    "gen_ai.tool.name": data.mcp_tool_name,
    "gen_ai.operation.name": "execute_tool",
    "network.transport": "pipe",
}
```
<!-- /docs-validate: hidden -->
```python
tool_attrs = {
    # 必要
    "mcp.method.name": "tools/call",
    
    # 推薦
    "mcp.server.name": data.mcp_server_name,
    "mcp.session.id": session.session_id,
    
    # GenAI 屬性
    "gen_ai.tool.name": data.mcp_tool_name,
    "gen_ai.operation.name": "execute_tool",
    "network.transport": "pipe",  # Copilot SDK 使用 stdio
}
```

## Span 命名慣例

Span 名稱請遵循以下模式：

| 操作 | Span 名稱模式 | 範例 |
|-----------|-------------------|---------|
| 代理程式調用 | `invoke_agent {agent_name}` | `invoke_agent weather-bot` |
| 聊天 | `chat` | `chat` |
| 工具執行 | `execute_tool {tool_name}` | `execute_tool fetch_weather` |
| MCP 工具 | `tools/call {tool_name}` | `tools/call read_file` |

## 指標 (Metrics)

您也可以匯出權杖使用量與操作時長的指標：

```python
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import ConsoleMetricExporter, PeriodicExportingMetricReader

# 設定指標
reader = PeriodicExportingMetricReader(ConsoleMetricExporter())
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

meter = metrics.get_meter(__name__)

# 建立指標
operation_duration = meter.create_histogram(
    name="gen_ai.client.operation.duration",
    description="Duration of GenAI operations",
    unit="ms"
)

token_usage = meter.create_counter(
    name="gen_ai.client.token.usage",
    description="Token usage count"
)

# 記錄指標
operation_duration.record(123.45, attributes={
    "gen_ai.operation.name": "invoke_agent",
    "gen_ai.request.model": "gpt-5",
})

token_usage.add(150, attributes={
    "gen_ai.token.type": "input",
    "gen_ai.operation.name": "invoke_agent",
})
```

## Azure Monitor 整合

對於使用 Azure Monitor 的生產環境觀測能力：

```python
from azure.monitor.opentelemetry import configure_azure_monitor

# 啟用 Azure Monitor
connection_string = "InstrumentationKey=..."
configure_azure_monitor(connection_string=connection_string)

# 您的檢測程式碼
```

在 Azure 入口網站中，於您的 Application Insights 資源 → Tracing 下查看追蹤。

## 最佳實踐

1. **務必關閉 Span**：使用 try/finally 區塊確保即使發生錯誤也會結束 Span。
2. **設定錯誤屬性**：在發生例外狀況時，設定 `error.type` 以及選用的 `error.message`。
3. **對工具使用子 Span**：為每次工具執行建立獨立的 Span。
4. **內容記錄需選擇性加入**：僅在明確啟用時記錄訊息內容與工具參數。
5. **截斷過大的值**：限制工具結果與參數的大小 (例如：512 字元)。
6. **設定完成原因**：操作成功完成時，務必設定 `gen_ai.response.finish_reasons`。
7. **包含模型資訊**：擷取請求與回應的模型名稱。

## 疑難排解

### 沒有出現 Span

1. 驗證 Tracer Provider 是否已設定：`trace.set_tracer_provider(provider)`。
2. 新增 Span Processor：`provider.add_span_processor(SimpleSpanProcessor(exporter))`。
3. 確保 Span 已結束：檢查是否遺漏了 `span.end()` 呼叫。

### 工具 Span 未顯示為子 Span

確保將工具 Span 附加至父內容 (context)：
<!-- docs-validate: hidden -->
```python
from opentelemetry import trace, context
from opentelemetry.trace import SpanKind

tracer = trace.get_tracer(__name__)
tool_span = tracer.start_span("test", kind=SpanKind.CLIENT)
tool_token = context.attach(trace.set_span_in_context(tool_span))
```
<!-- /docs-validate: hidden -->
```python
tool_token = context.attach(trace.set_span_in_context(tool_span))
```

### 非同步程式碼中的 Context 警告

在非同步串流程式碼中，您可能會看到 "Failed to detach context" 警告。這些是預期中的，且不會影響追蹤的正確性。

## 參考資料

- [OpenTelemetry GenAI 語意慣例](https://opentelemetry.io/docs/specs/semconv/gen-ai/)
- [OpenTelemetry MCP 語意慣例](https://opentelemetry.io/docs/specs/semconv/gen-ai/mcp/)
- [OpenTelemetry Python SDK](https://opentelemetry.io/docs/instrumentation/python/)
- [GenAI 語意慣例 v1.34.0](https://opentelemetry.io/schemas/1.34.0)
- [Copilot SDK 文件](https://github.com/github/copilot-sdk)
