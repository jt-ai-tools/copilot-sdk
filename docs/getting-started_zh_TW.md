# 構建您的第一個 Copilot 驅動應用程式

在本教程中，您將使用 Copilot SDK 構建一個命令行助手。您將從基礎開始，添加串流響應，然後添加自定義工具 — 賦予 Copilot 調用您代碼的能力。

**您將構建的內容：**

```
您：西雅圖的天氣怎麼樣？
Copilot：讓我查一下西雅圖的天氣...
         目前華氏 62 度，多雲，有降雨機率。
         典型的西雅圖天氣！

您：東京呢？
Copilot：東京目前華氏 75 度，晴天。是個適合戶外活動的好日子！
```

## 前提條件

在開始之前，請確保您已具備：

- **GitHub Copilot CLI** 已安裝並完成身份驗證（[安裝指南](https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli)）
- 您偏好的語言運行環境：
  - **Node.js** 18+ 或 **Python** 3.8+ 或 **Go** 1.21+ 或 **.NET** 8.0+

驗證 CLI 是否正常運作：

```bash
copilot --version
```

## 步驟 1：安裝 SDK

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

首先，建立一個新目錄並初始化您的專案：

```bash
mkdir copilot-demo && cd copilot-demo
npm init -y --init-type module
```

然後安裝 SDK 和 TypeScript 執行器：

```bash
npm install @github/copilot-sdk tsx
```

</details>

<details>
<summary><strong>Python</strong></summary>

```bash
pip install github-copilot-sdk
```

</details>

<details>
<summary><strong>Go</strong></summary>

首先，建立一個新目錄並初始化您的模組：

```bash
mkdir copilot-demo && cd copilot-demo
go mod init copilot-demo
```

然後安裝 SDK：

```bash
go get github.com/github/copilot-sdk/go
```

</details>

<details>
<summary><strong>.NET</strong></summary>

首先，建立一個新的主控台專案：

```bash
dotnet new console -n CopilotDemo && cd CopilotDemo
```

然後添加 SDK：

```bash
dotnet add package GitHub.Copilot.SDK
```

</details>

## 步驟 2：發送您的第一條訊息

建立一個新檔案並添加以下代碼。這是使用 SDK 最簡單的方法 — 大約只需 5 行代碼。

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

建立 `index.ts`：

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({ model: "gpt-4.1" });

const response = await session.sendAndWait({ prompt: "2 + 2 等於多少？" });
console.log(response?.data.content);

await client.stop();
process.exit(0);
```

執行它：

```bash
npx tsx index.ts
```

</details>

<details>
<summary><strong>Python</strong></summary>

建立 `main.py`：

```python
import asyncio
from copilot import CopilotClient

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({"model": "gpt-4.1"})
    response = await session.send_and_wait({"prompt": "2 + 2 等於多少？"})

    print(response.data.content)

    await client.stop()

asyncio.run(main())
```

執行它：

```bash
python main.py
```

</details>

<details>
<summary><strong>Go</strong></summary>

建立 `main.go`：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	copilot "github.com/github/copilot-sdk/go"
)

func main() {
	ctx := context.Background()
	client := copilot.NewClient(nil)
	if err := client.Start(ctx); err != nil {
		log.Fatal(err)
	}
	defer client.Stop()

	session, err := client.CreateSession(ctx, &copilot.SessionConfig{Model: "gpt-4.1"})
	if err != nil {
		log.Fatal(err)
	}

	response, err := session.SendAndWait(ctx, copilot.MessageOptions{Prompt: "2 + 2 等於多少？"})
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(*response.Data.Content)
	os.Exit(0)
}
```

執行它：

```bash
go run main.go
```

</details>

<details>
<summary><strong>.NET</strong></summary>

建立一個新的主控台專案並將以下代碼添加到 `Program.cs`：

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig { Model = "gpt-4.1" });

var response = await session.SendAndWaitAsync(new MessageOptions { Prompt = "2 + 2 等於多少？" });
Console.WriteLine(response?.Data.Content);
```

執行它：

```bash
dotnet run
```

</details>

**您應該會看到：**

```
4
```

恭喜！您剛剛構建了您的第一個由 Copilot 驅動的應用程式。

## 步驟 3：添加串流響應

目前，您必須等待完整的響應生成後才能看到任何內容。讓我們透過串流響應來使其具有交互性。

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

更新 `index.ts`：

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
});

// 監聽響應區塊
session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});
session.on("session.idle", () => {
    console.log(); // 完成後換行
});

await session.sendAndWait({ prompt: "講一個短笑話" });

await client.stop();
process.exit(0);
```

</details>

<details>
<summary><strong>Python</strong></summary>

更新 `main.py`：

```python
import asyncio
import sys
from copilot import CopilotClient
from copilot.generated.session_events import SessionEventType

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-4.1",
        "streaming": True,
    })

    # 監聽響應區塊
    def handle_event(event):
        if event.type == SessionEventType.ASSISTANT_MESSAGE_DELTA:
            sys.stdout.write(event.data.delta_content)
            sys.stdout.flush()
        if event.type == SessionEventType.SESSION_IDLE:
            print()  # 完成後換行

    session.on(handle_event)

    await session.send_and_wait({"prompt": "講一個短笑話"})

    await client.stop()

asyncio.run(main())
```

</details>

<details>
<summary><strong>Go</strong></summary>

更新 `main.go`：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"os"

	copilot "github.com/github/copilot-sdk/go"
)

func main() {
	ctx := context.Background()
	client := copilot.NewClient(nil)
	if err := client.Start(ctx); err != nil {
		log.Fatal(err)
	}
	defer client.Stop()

	session, err := client.CreateSession(ctx, &copilot.SessionConfig{
		Model:     "gpt-4.1",
		Streaming: true,
	})
	if err != nil {
		log.Fatal(err)
	}

	// 監聽響應區塊
	session.On(func(event copilot.SessionEvent) {
		if event.Type == "assistant.message_delta" {
			fmt.Print(*event.Data.DeltaContent)
		}
		if event.Type == "session.idle" {
			fmt.Println()
		}
	})

	_, err = session.SendAndWait(ctx, copilot.MessageOptions{Prompt: "講一個短笑話"})
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(0)
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

更新 `Program.cs`：

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-4.1",
    Streaming = true,
});

// 監聽響應區塊
session.On(ev =>
{
    if (ev is AssistantMessageDeltaEvent deltaEvent)
    {
        Console.Write(deltaEvent.Data.DeltaContent);
    }
    if (ev is SessionIdleEvent)
    {
        Console.WriteLine();
    }
});

await session.SendAndWaitAsync(new MessageOptions { Prompt = "講一個短笑話" });
```

</details>

再次執行代碼。您將看到響應逐字出現。

### 事件訂閱方法

SDK 提供了訂閱會話事件的方法：

| 方法 | 描述 |
|--------|-------------|
| `on(handler)` | 訂閱所有事件；返回取消訂閱函數 |
| `on(eventType, handler)` | 訂閱特定事件類型（僅限 Node.js/TypeScript）；返回取消訂閱函數 |

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
// 訂閱所有事件
const unsubscribeAll = session.on((event) => {
    console.log("事件：", event.type);
});

// 訂閱特定事件類型
const unsubscribeIdle = session.on("session.idle", (event) => {
    console.log("會話已閒置");
});

// 之後取消訂閱：
unsubscribeAll();
unsubscribeIdle();
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
# 訂閱所有事件
unsubscribe = session.on(lambda event: print(f"事件：{event.type}"))

# 在處理器中過濾事件類型
def handle_event(event):
    if event.type == SessionEventType.SESSION_IDLE:
        print("會話已閒置")
    elif event.type == SessionEventType.ASSISTANT_MESSAGE:
        print(f"訊息：{event.data.content}")

unsubscribe = session.on(handle_event)

# 之後取消訂閱：
unsubscribe()
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
// 訂閱所有事件
unsubscribe := session.On(func(event copilot.SessionEvent) {
    fmt.Println("事件：", event.Type)
})

// 在處理器中過濾事件類型
session.On(func(event copilot.SessionEvent) {
    if event.Type == "session.idle" {
        fmt.Println("會話已閒置")
    } else if event.Type == "assistant.message" {
        fmt.Println("訊息：", *event.Data.Content)
    }
})

// 之後取消訂閱：
unsubscribe()
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
// 訂閱所有事件
var unsubscribe = session.On(ev => Console.WriteLine($"事件：{ev.Type}"));

// 使用模式比對過濾事件類型
session.On(ev =>
{
    switch (ev)
    {
        case SessionIdleEvent:
            Console.WriteLine("會話已閒置");
            break;
        case AssistantMessageEvent msg:
            Console.WriteLine($"訊息：{msg.Data.Content}");
            break;
    }
});

// 之後取消訂閱：
unsubscribe.Dispose();
```

</details>

## 步驟 4：添加自定義工具

現在進入強大的部分。讓我們透過定義自定義工具來賦予 Copilot 調用您代碼的能力。我們將建立一個簡單的天氣查詢工具。

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

更新 `index.ts`：

```typescript
import { CopilotClient, defineTool } from "@github/copilot-sdk";

// 定義一個 Copilot 可以調用的工具
const getWeather = defineTool("get_weather", {
    description: "獲取城市的當前天氣",
    parameters: {
        type: "object",
        properties: {
            city: { type: "string", description: "城市名稱" },
        },
        required: ["city"],
    },
    handler: async (args: { city: string }) => {
        const { city } = args;
        // 在實際應用中，您會在這裡調用天氣 API
        const conditions = ["晴天", "多雲", "有雨", "局部多雲"];
        const temp = Math.floor(Math.random() * 30) + 50;
        const condition = conditions[Math.floor(Math.random() * conditions.length)];
        return { city, temperature: `${temp}°F`, condition };
    },
});

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
    tools: [getWeather],
});

session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});

session.on("session.idle", () => {
    console.log(); // 完成後換行
});

await session.sendAndWait({
    prompt: "西雅圖和東京的天氣怎麼樣？",
});

await client.stop();
process.exit(0);
```

</details>

<details>
<summary><strong>Python</strong></summary>

更新 `main.py`：

```python
import asyncio
import random
import sys
from copilot import CopilotClient
from copilot.tools import define_tool
from copilot.generated.session_events import SessionEventType
from pydantic import BaseModel, Field

# 使用 Pydantic 定義工具參數
class GetWeatherParams(BaseModel):
    city: str = Field(description="要獲取天氣的城市名稱")

# 定義一個 Copilot 可以調用的工具
@define_tool(description="獲取城市的當前天氣")
async def get_weather(params: GetWeatherParams) -> dict:
    city = params.city
    # 在實際應用中，您會在這裡調用天氣 API
    conditions = ["晴天", "多雲", "有雨", "局部多雲"]
    temp = random.randint(50, 80)
    condition = random.choice(conditions)
    return {"city": city, "temperature": f"{temp}°F", "condition": condition}

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-4.1",
        "streaming": True,
        "tools": [get_weather],
    })

    def handle_event(event):
        if event.type == SessionEventType.ASSISTANT_MESSAGE_DELTA:
            sys.stdout.write(event.data.delta_content)
            sys.stdout.flush()
        if event.type == SessionEventType.SESSION_IDLE:
            print()

    session.on(handle_event)

    await session.send_and_wait({
        "prompt": "西雅圖和東京的天氣怎麼樣？"
    })

    await client.stop()

asyncio.run(main())
```

</details>

<details>
<summary><strong>Go</strong></summary>

更新 `main.go`：

```go
package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"

	copilot "github.com/github/copilot-sdk/go"
)

// 定義參數類型
type WeatherParams struct {
	City string `json:"city" jsonschema:"城市名稱"`
}

// 定義返回類型
type WeatherResult struct {
	City        string `json:"city"`
	Temperature string `json:"temperature"`
	Condition   string `json:"condition"`
}

func main() {
	ctx := context.Background()

	// 定義一個 Copilot 可以調用的工具
	getWeather := copilot.DefineTool(
		"get_weather",
		"獲取城市的當前天氣",
		func(params WeatherParams, inv copilot.ToolInvocation) (WeatherResult, error) {
			// 在實際應用中，您會在這裡調用天氣 API
			conditions := []string{"晴天", "多雲", "有雨", "局部多雲"}
			temp := rand.Intn(30) + 50
			condition := conditions[rand.Intn(len(conditions))]
			return WeatherResult{
				City:        params.City,
				Temperature: fmt.Sprintf("%d°F", temp),
				Condition:   condition,
			}, nil
		},
	)

	client := copilot.NewClient(nil)
	if err := client.Start(ctx); err != nil {
		log.Fatal(err)
	}
	defer client.Stop()

	session, err := client.CreateSession(ctx, &copilot.SessionConfig{
		Model:     "gpt-4.1",
		Streaming: true,
		Tools:     []copilot.Tool{getWeather},
	})
	if err != nil {
		log.Fatal(err)
	}

	session.On(func(event copilot.SessionEvent) {
		if event.Type == "assistant.message_delta" {
			fmt.Print(*event.Data.DeltaContent)
		}
		if event.Type == "session.idle" {
			fmt.Println()
		}
	})

	_, err = session.SendAndWait(ctx, copilot.MessageOptions{
		Prompt: "西雅圖和東京的天氣怎麼樣？",
	})
	if err != nil {
		log.Fatal(err)
	}
	os.Exit(0)
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

更新 `Program.cs`：

```csharp
using GitHub.Copilot.SDK;
using Microsoft.Extensions.AI;
using System.ComponentModel;

await using var client = new CopilotClient();

// 定義一個 Copilot 可以調用的工具
var getWeather = AIFunctionFactory.Create(
    ([Description("城市名稱")] string city) =>
    {
        // 在實際應用中，您會在這裡調用天氣 API
        var conditions = new[] { "晴天", "多雲", "有雨", "局部多雲" };
        var temp = Random.Shared.Next(50, 80);
        var condition = conditions[Random.Shared.Next(conditions.Length)];
        return new { city, temperature = $"{temp}°F", condition };
    },
    "get_weather",
    "獲取城市的當前天氣"
);

await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-4.1",
    Streaming = true,
    Tools = [getWeather],
});

session.On(ev =>
{
    if (ev is AssistantMessageDeltaEvent deltaEvent)
    {
        Console.Write(deltaEvent.Data.DeltaContent);
    }
    if (ev is SessionIdleEvent)
    {
        Console.WriteLine();
    }
});

await session.SendAndWaitAsync(new MessageOptions
{
    Prompt = "西雅圖和東京的天氣怎麼樣？",
});
```

</details>

執行它，您將看到 Copilot 調用您的工具來獲取天氣數據，然後根據結果進行響應！

## 步驟 5：構建一個交互式助手

讓我們將所有內容整合到一個實用的交互式助手中：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient, defineTool } from "@github/copilot-sdk";
import * as readline from "readline";

const getWeather = defineTool("get_weather", {
    description: "獲取城市的當前天氣",
    parameters: {
        type: "object",
        properties: {
            city: { type: "string", description: "城市名稱" },
        },
        required: ["city"],
    },
    handler: async ({ city }) => {
        const conditions = ["晴天", "多雲", "有雨", "局部多雲"];
        const temp = Math.floor(Math.random() * 30) + 50;
        const condition = conditions[Math.floor(Math.random() * conditions.length)];
        return { city, temperature: `${temp}°F`, condition };
    },
});

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
    tools: [getWeather],
});

session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
});

console.log("🌤️  天氣助手（輸入 'exit' 退出）");
console.log("   試試看：'巴黎的天氣怎麼樣？'\n");

const prompt = () => {
    rl.question("您：", async (input) => {
        if (input.toLowerCase() === "exit") {
            await client.stop();
            rl.close();
            return;
        }

        process.stdout.write("助手：");
        await session.sendAndWait({ prompt: input });
        console.log("\n");
        prompt();
    });
};

prompt();
```

執行命令：

```bash
npx tsx weather-assistant.ts
```

</details>

<details>
<summary><strong>Python</strong></summary>

建立 `weather_assistant.py`：

```python
import asyncio
import random
import sys
from copilot import CopilotClient
from copilot.tools import define_tool
from copilot.generated.session_events import SessionEventType
from pydantic import BaseModel, Field

class GetWeatherParams(BaseModel):
    city: str = Field(description="要獲取天氣的城市名稱")

@define_tool(description="獲取城市的當前天氣")
async def get_weather(params: GetWeatherParams) -> dict:
    city = params.city
    conditions = ["晴天", "多雲", "有雨", "局部多雲"]
    temp = random.randint(50, 80)
    condition = random.choice(conditions)
    return {"city": city, "temperature": f"{temp}°F", "condition": condition}

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-4.1",
        "streaming": True,
        "tools": [get_weather],
    })

    def handle_event(event):
        if event.type == SessionEventType.ASSISTANT_MESSAGE_DELTA:
            sys.stdout.write(event.data.delta_content)
            sys.stdout.flush()

    session.on(handle_event)

    print("🌤️  天氣助手（輸入 'exit' 退出）")
    print("   試試看：'巴黎的天氣怎麼樣？' 或 '比較紐約和洛杉磯的天氣'\n")

    while True:
        try:
            user_input = input("您：")
        except EOFError:
            break

        if user_input.lower() == "exit":
            break

        sys.stdout.write("助手：")
        await session.send_and_wait({"prompt": user_input})
        print("\n")

    await client.stop()

asyncio.run(main())
```

執行命令：

```bash
python weather_assistant.py
```

</details>

<details>
<summary><strong>Go</strong></summary>

建立 `weather-assistant.go`：

```go
package main

import (
	"bufio"
	"context"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"

	copilot "github.com/github/copilot-sdk/go"
)

type WeatherParams struct {
	City string `json:"city" jsonschema:"城市名稱"`
}

type WeatherResult struct {
	City        string `json:"city"`
	Temperature string `json:"temperature"`
	Condition   string `json:"condition"`
}

func main() {
	ctx := context.Background()

	getWeather := copilot.DefineTool(
		"get_weather",
		"獲取城市的當前天氣",
		func(params WeatherParams, inv copilot.ToolInvocation) (WeatherResult, error) {
			conditions := []string{"晴天", "多雲", "有雨", "局部多雲"}
			temp := rand.Intn(30) + 50
			condition := conditions[rand.Intn(len(conditions))]
			return WeatherResult{
				City:        params.City,
				Temperature: fmt.Sprintf("%d°F", temp),
				Condition:   condition,
			}, nil
		},
	)

	client := copilot.NewClient(nil)
	if err := client.Start(ctx); err != nil {
		log.Fatal(err)
	}
	defer client.Stop()

	session, err := client.CreateSession(ctx, &copilot.SessionConfig{
		Model:     "gpt-4.1",
		Streaming: true,
		Tools:     []copilot.Tool{getWeather},
	})
	if err != nil {
		log.Fatal(err)
	}

	session.On(func(event copilot.SessionEvent) {
		if event.Type == "assistant.message_delta" {
			if event.Data.DeltaContent != nil {
				fmt.Print(*event.Data.DeltaContent)
			}
		}
		if event.Type == "session.idle" {
			fmt.Println()
		}
	})

	fmt.Println("🌤️  天氣助手（輸入 'exit' 退出）")
	fmt.Println("   試試看：'巴黎的天氣怎麼樣？' 或 '比較紐約和洛杉磯的天氣'\n")

	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("您：")
		if !scanner.Scan() {
			break
		}
		input := scanner.Text()
		if strings.ToLower(input) == "exit" {
			break
		}

		fmt.Print("助手：")
		_, err = session.SendAndWait(ctx, copilot.MessageOptions{Prompt: input})
		if err != nil {
			fmt.Fprintf(os.Stderr, "錯誤：%v\n", err)
			break
		}
		fmt.Println()
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "輸入錯誤：%v\n", err)
	}
}
```

執行命令：

```bash
go run weather-assistant.go
```

</details>

<details>
<summary><strong>.NET</strong></summary>

建立一個新的主控台專案並更新 `Program.cs`：

```csharp
using GitHub.Copilot.SDK;
using Microsoft.Extensions.AI;
using System.ComponentModel;

// 使用 AIFunctionFactory 定義天氣工具
var getWeather = AIFunctionFactory.Create(
    ([Description("城市名稱")] string city) =>
    {
        var conditions = new[] { "晴天", "多雲", "有雨", "局部多雲" };
        var temp = Random.Shared.Next(50, 80);
        var condition = conditions[Random.Shared.Next(conditions.Length)];
        return new { city, temperature = $"{temp}°F", condition };
    },
    "get_weather",
    "獲取城市的當前天氣");

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-4.1",
    Streaming = true,
    Tools = [getWeather]
});

// 監聽響應區塊
session.On(ev =>
{
    if (ev is AssistantMessageDeltaEvent deltaEvent)
    {
        Console.Write(deltaEvent.Data.DeltaContent);
    }
    if (ev is SessionIdleEvent)
    {
        Console.WriteLine();
    }
});

Console.WriteLine("🌤️  天氣助手（輸入 'exit' 退出）");
Console.WriteLine("   試試看：'巴黎的天氣怎麼樣？' 或 '比較紐約和洛杉磯的天氣'\n");

while (true)
{
    Console.Write("您：");
    var input = Console.ReadLine();

    if (string.IsNullOrEmpty(input) || input.Equals("exit", StringComparison.OrdinalIgnoreCase))
    {
        break;
    }

    Console.Write("助手：");
    await session.SendAndWaitAsync(new MessageOptions { Prompt = input });
    Console.WriteLine("\n");
}
```

執行命令：

```bash
dotnet run
```

</details>


**會話範例：**

```
🌤️  天氣助手（輸入 'exit' 退出）
   試試看：'巴黎的天氣怎麼樣？' 或 '比較紐約和洛杉磯的天氣'

您：西雅圖的天氣怎麼樣？
助手：讓我查一下西雅圖的天氣...
西雅圖目前是華氏 62 度，多雲。

您：東京和倫敦呢？
助手：我會為您查詢這兩個城市：
- 東京：華氏 75 度，晴天
- 倫敦：華氏 58 度，有雨

您：exit
```

您已經構建了一個帶有自定義工具的助手，Copilot 可以調用它！

---

## 工具是如何運作的

當您定義一個工具時，您是在告訴 Copilot：
1. **工具的功能**（描述）
2. **所需的參數**（架構）
3. **要執行的代碼**（處理器）

Copilot 會根據用戶的問題決定何時調用您的工具。當它調用時：
1. Copilot 發送一個帶有參數的工具調用請求
2. SDK 執行您的處理器函數
3. 結果被送回給 Copilot
4. Copilot 將結果整合到其響應中

---

## 下一步是什麼？

現在您已經掌握了基礎知識，這裡有更多強大的功能供您探索：

### 連接到 MCP 伺服器

MCP (Model Context Protocol) 伺服器提供預建的工具。連接到 GitHub 的 MCP 伺服器，讓 Copilot 存取存儲庫、議題 (Issues) 和拉取請求 (Pull Requests)：

```typescript
const session = await client.createSession({
    mcpServers: {
        github: {
            type: "http",
            url: "https://api.githubcopilot.com/mcp/",
        },
    },
});
```

📖 **[完整的 MCP 文件 →](./features/mcp_zh_TW.md)** - 了解本地與遠端伺服器、所有配置選項以及疑難排解。

### 建立自定義代理

為特定任務定義專門的 AI 角色：

```typescript
const session = await client.createSession({
    customAgents: [{
        name: "pr-reviewer",
        displayName: "PR Reviewer",
        description: "根據最佳實踐審查拉取請求",
        prompt: "您是一位資深的代碼審查專家。請專注於安全性、效能和可維護性。",
    }],
});
```

> **提示：** 您也可以在會話配置中設置 `agent: "pr-reviewer"`，以便從一開始就預選此代理。詳情請參閱 [自定義代理指南](./features/custom-agents_zh_TW.md#selecting-an-agent-at-session-creation)。

### 自定義系統訊息

控制 AI 的行為和個性：

```typescript
const session = await client.createSession({
    systemMessage: {
        content: "您是我們工程團隊的得力助手。請務必保持簡潔。",
    },
});
```

---

## 連接到外部 CLI 伺服器

默認情況下，SDK 會自動管理 Copilot CLI 的進程生命週期，根據需要啟動和停止 CLI。但是，您也可以單獨以伺服器模式執行 CLI，並讓 SDK 連接到它。這在以下情況很有用：

- **調試**：在 SDK 重啟之間保持 CLI 執行，以便檢查日誌
- **資源共享**：多個 SDK 用戶端可以連接到同一個 CLI 伺服器
- **開發**：使用自定義設置或在不同環境中執行 CLI

### 以伺服器模式執行 CLI

使用 `--headless` 標誌啟動伺服器模式下的 CLI，並可選擇指定端口：

```bash
copilot --headless --port 4321
```

如果您沒有指定端口，CLI 會選擇一個隨機的可用端口。

### 將 SDK 連接到外部伺服器

CLI 以伺服器模式執行後，配置您的 SDK 用戶端以使用 "cli url" 選項連接到它：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient, approveAll } from "@github/copilot-sdk";

const client = new CopilotClient({
    cliUrl: "localhost:4321"
});

// 像往常一樣使用用戶端
const session = await client.createSession({ onPermissionRequest: approveAll });
// ...
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient, PermissionHandler

client = CopilotClient({
    "cli_url": "localhost:4321"
})
await client.start()

# 像往常一樣使用用戶端
session = await client.create_session({"on_permission_request": PermissionHandler.approve_all})
# ...
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
import copilot "github.com/github/copilot-sdk/go"

client := copilot.NewClient(&copilot.ClientOptions{
    CLIUrl: "localhost:4321",
})

if err := client.Start(ctx); err != nil {
    log.Fatal(err)
}
defer client.Stop()

// 像往常一樣使用用戶端
session, err := client.CreateSession(ctx, &copilot.SessionConfig{
    OnPermissionRequest: copilot.PermissionHandler.ApproveAll,
})
// ...
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

using var client = new CopilotClient(new CopilotClientOptions
{
    CliUrl = "localhost:4321",
    UseStdio = false
});

// 像往常一樣使用用戶端
await using var session = await client.CreateSessionAsync(new()
{
    OnPermissionRequest = PermissionHandler.ApproveAll
});
// ...
```

</details>

**注意：** 當提供 `cli_url` / `cliUrl` / `CLIUrl` 時，SDK 不會產生或管理 CLI 進程 — 它只會連接到指定 URL 的現有伺服器。

---

## 了解更多

- [身份驗證指南](./auth/index_zh_TW.md) - GitHub OAuth、環境變數和 BYOK
- [BYOK (自備金鑰)](./auth/byok_zh_TW.md) - 使用您自己的 Azure AI Foundry、OpenAI 等 API 金鑰。
- [Node.js SDK 參考](../nodejs/README_zh_TW.md)
- [Python SDK 參考](../python/README_zh_TW.md)
- [Go SDK 參考](../go/README_zh_TW.md)
- [.NET SDK 參考](../dotnet/README_zh_TW.md)
- [使用 MCP 伺服器](./features/mcp_zh_TW.md) - 透過模型上下文協議整合外部工具
- [GitHub MCP 伺服器文件](https://github.com/github/github-mcp-server)
- [MCP 伺服器目錄](https://github.com/modelcontextprotocol/servers) - 探索更多 MCP 伺服器

---

**您做到了！** 您已經了解了 GitHub Copilot SDK 的核心概念：
- ✅ 建立用戶端和會話
- ✅ 發送訊息並接收響應
- ✅ 串流傳輸即時輸出
- ✅ 定義 Copilot 可以調用的自定義工具

現在去構建一些精彩的東西吧！ 🚀
