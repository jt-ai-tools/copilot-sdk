# 自訂技能 (Custom Skills)

技能 (Skills) 是可重複使用的提示詞模組，可擴展 Copilot 的功能。從目錄載入技能，為 Copilot 提供特定領域或工作流程的專業能力。

## 概覽

技能是一個具名的目錄，其中包含一個 `SKILL.md` 檔案 — 這是一個為 Copilot 提供指令的 Markdown 文件。載入後，技能的內容將注入到工作階段內容中。

技能允許您：
- 將領域專業知識打包成可重複使用的模組
- 在不同專案中共享專業行為
- 組織複雜的代理設定
- 為每個工作階段啟用/停用功能

## 載入技能

建立工作階段時指定包含技能的目錄：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    skillDirectories: [
        "./skills/code-review",
        "./skills/documentation",
    ],
    onPermissionRequest: async () => ({ kind: "approved" }),
});

// Copilot 現在可以存取這些目錄中的技能
await session.sendAndWait({ prompt: "檢查此程式碼是否存在安全性問題" });
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
from copilot import CopilotClient
from copilot.types import PermissionRequestResult

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session({
        "model": "gpt-4.1",
        "skill_directories": [
            "./skills/code-review",
            "./skills/documentation",
        ],
        "on_permission_request": lambda req, inv: PermissionRequestResult(kind="approved"),
    })

    # Copilot 現在可以存取這些目錄中的技能
    await session.send_and_wait({"prompt": "檢查此程式碼是否存在安全性問題"})

    await client.stop()
```

</details>

<details>
<summary><strong>Go</strong></summary>

```go
package main

import (
    "context"
    "log"
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
        Model: "gpt-4.1",
        SkillDirectories: []string{
            "./skills/code-review",
            "./skills/documentation",
        },
        OnPermissionRequest: func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
            return copilot.PermissionRequestResult{Kind: copilot.PermissionRequestResultKindApproved}, nil
        },
    })
    if err != nil {
        log.Fatal(err)
    }

    // Copilot 現在可以存取這些目錄中的技能
    _, err = session.SendAndWait(ctx, copilot.MessageOptions{
        Prompt: "檢查此程式碼是否存在安全性問題",
    })
    if err != nil {
        log.Fatal(err)
    }
}
```

</details>

<details>
<summary><strong>.NET</strong></summary>

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-4.1",
    SkillDirectories = new List<string>
    {
        "./skills/code-review",
        "./skills/documentation",
    },
    OnPermissionRequest = (req, inv) =>
        Task.FromResult(new PermissionRequestResult { Kind = PermissionRequestResultKind.Approved }),
});

// Copilot 現在可以存取這些目錄中的技能
await session.SendAndWaitAsync(new MessageOptions
{
    Prompt = "檢查此程式碼是否存在安全性問題"
});
```

</details>

## 停用技能

在保持其他技能啟用的同時，停用特定技能：

<details open>
<summary><strong>Node.js / TypeScript</strong></summary>

```typescript
const session = await client.createSession({
    skillDirectories: ["./skills"],
    disabledSkills: ["experimental-feature", "deprecated-tool"],
});
```

</details>

<details>
<summary><strong>Python</strong></summary>

```python
session = await client.create_session({
    "skill_directories": ["./skills"],
    "disabled_skills": ["experimental-feature", "deprecated-tool"],
})
```

</details>

<details>
<summary><strong>Go</strong></summary>

<!-- docs-validate: hidden -->
```go
package main

import (
	"context"
	copilot "github.com/github/copilot-sdk/go"
)

func main() {
	ctx := context.Background()
	client := copilot.NewClient(nil)

	session, _ := client.CreateSession(ctx, &copilot.SessionConfig{
		SkillDirectories: []string{"./skills"},
		DisabledSkills:   []string{"experimental-feature", "deprecated-tool"},
		OnPermissionRequest: func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
			return copilot.PermissionRequestResult{Kind: copilot.PermissionRequestResultKindApproved}, nil
		},
	})
	_ = session
}
```
<!-- /docs-validate: hidden -->

```go
session, _ := client.CreateSession(context.Background(), &copilot.SessionConfig{
    SkillDirectories: []string{"./skills"},
    DisabledSkills:   []string{"experimental-feature", "deprecated-tool"},
})
```

</details>

<details>
<summary><strong>.NET</strong></summary>

<!-- docs-validate: hidden -->
```csharp
using GitHub.Copilot.SDK;

public static class SkillsExample
{
    public static async Task Main()
    {
        await using var client = new CopilotClient();

        var session = await client.CreateSessionAsync(new SessionConfig
        {
            SkillDirectories = new List<string> { "./skills" },
            DisabledSkills = new List<string> { "experimental-feature", "deprecated-tool" },
            OnPermissionRequest = (req, inv) =>
                Task.FromResult(new PermissionRequestResult { Kind = PermissionRequestResultKind.Approved }),
        });
    }
}
```
<!-- /docs-validate: hidden -->

```csharp
var session = await client.CreateSessionAsync(new SessionConfig
{
    SkillDirectories = new List<string> { "./skills" },
    DisabledSkills = new List<string> { "experimental-feature", "deprecated-tool" },
});
```

</details>

## 技能目錄結構

每個技能都是一個具名的子目錄，其中包含一個 `SKILL.md` 檔案：

```
skills/
├── code-review/
│   └── SKILL.md
└── documentation/
    └── SKILL.md
```

`skillDirectories` 選項指向父目錄（例如 `./skills`）。CLI 會在直接子目錄中發現所有 `SKILL.md` 檔案。

### SKILL.md 格式

`SKILL.md` 檔案是一個帶有選用 YAML frontmatter 的 Markdown 文件：

```markdown
---
name: code-review
description: 專業的程式碼審查功能
---

# 程式碼審查指南 (Code Review Guidelines)

在審查程式碼時，請務必檢查：

1. **安全性漏洞** - SQL 注入、XSS 等。
2. **效能問題** - N+1 查詢、記憶體洩漏
3. **程式碼風格** - 一致的格式、命名慣例
4. **測試涵蓋範圍** - 關鍵路徑是否經過測試？

提供具體的行號參考和建議的修復方法。
```

Frontmatter 欄位：
- **`name`** — 技能的識別碼（與 `disabledSkills` 一起使用以選擇性地停用它）。如果省略，則使用目錄名稱。
- **`description`** — 技能功能的簡短說明。

Markdown 本文包含載入技能時注入工作階段內容中的指令。

## 設定選項 (Configuration Options)

### SessionConfig 技能欄位

| 語言 | 欄位 | 類型 | 說明 |
|----------|-------|------|-------------|
| Node.js | `skillDirectories` | `string[]` | 載入技能的目錄 |
| Node.js | `disabledSkills` | `string[]` | 要停用的技能 |
| Python | `skill_directories` | `list[str]` | 載入技能的目錄 |
| Python | `disabled_skills` | `list[str]` | 要停用的技能 |
| Go | `SkillDirectories` | `[]string` | 載入技能的目錄 |
| Go | `DisabledSkills` | `[]string` | 要停用的技能 |
| .NET | `SkillDirectories` | `List<string>` | 載入技能的目錄 |
| .NET | `DisabledSkills` | `List<string>` | 要停用的技能 |

## 最佳實作

1. **依領域組織** - 將相關技能分組在一起（例如 `skills/security/`, `skills/testing/`）

2. **使用 frontmatter** - 在 YAML frontmatter 中包含 `name` 和 `description` 以增加清晰度

3. **記錄依賴關係** - 註明技能需要的任何工具過或 MCP 伺服器

4. **單獨測試技能** - 在組合技能之前驗證它們是否正常運作

5. **使用相對路徑** - 保持技能在不同環境中的可移植性

## 與其他功能組合

### 技能 + 自訂代理

技能可與自訂代理配合使用：

```typescript
const session = await client.createSession({
    skillDirectories: ["./skills/security"],
    customAgents: [{
        name: "security-auditor",
        description: "專注於安全性的程式碼審查者",
        prompt: "專注於 OWASP Top 10 漏洞",
    }],
    onPermissionRequest: async () => ({ kind: "approved" }),
});
```

### 技能 + MCP 伺服器

技能可以補充 MCP 伺服器功能：

```typescript
const session = await client.createSession({
    skillDirectories: ["./skills/database"],
    mcpServers: {
        postgres: {
            type: "local",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-postgres"],
            tools: ["*"],
        },
    },
    onPermissionRequest: async () => ({ kind: "approved" }),
});
```

## 疑難排解

### 技能未載入

1. **檢查路徑是否存在** - 驗證技能目錄路徑是否正確，且包含具有 `SKILL.md` 檔案的子目錄
2. **檢查權限** - 確保 SDK 可以讀取該目錄
3. **檢查 SKILL.md 格式** - 驗證 Markdown 是否格式正確，且任何 YAML frontmatter 使用有效的語法
4. **啟用偵錯日誌** - 將 `logLevel` 設定為 `"debug"` 以查看技能載入日誌

### 技能衝突

如果多個技能提供衝突的指令：
- 使用 `disabledSkills` 排除衝突的技能
- 重新組織技能目錄以避免重疊

## 延伸閱讀

- [自訂代理](../getting-started_zh_TW.md#create-custom-agents) - 定義專業的 AI 人物角色
- [自訂工具](../getting-started_zh_TW.md#step-4-add-a-custom-tool) - 建構您自己的工具
- [MCP 伺服器](./mcp_zh_TW.md) - 連接外部工具提供者
