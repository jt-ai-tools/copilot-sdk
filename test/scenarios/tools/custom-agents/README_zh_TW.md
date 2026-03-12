# 設定範例：自定義代理程式

示範如何為 Copilot SDK 設定**自定義代理程式定義**，以限制代理程式可以使用的工具。這驗證了：

1. **代理程式定義** — `customAgents` 工作階段設定接受包含名稱、描述、工具列表和自定義提示詞的代理程式定義。
2. **工具範圍設定** — 每個自定義代理程式都可以被限制為可用工具的一個子集（例如 `grep`、`glob`、`view` 等唯讀工具）。
3. **代理程式感知** — 模型能夠辨識並描述已設定的自定義代理程式。

## 每個範例的功能

1. 建立一個包含 "researcher" 代理程式的 `customAgents` 陣列的工作階段。
2. researcher 代理程式被限制在唯讀工具範圍：`grep`、`glob`、`view`。
3. 發送：_"有哪些可用的自定義代理程式？描述 researcher 代理程式及其功能。"_
4. 列印回應 — 回應應該描述 researcher 代理程式及其工具限制。

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `customAgents[0].name` | `"researcher"` | 代理程式的內部識別碼 |
| `customAgents[0].displayName` | `"Research Agent"` | 人類可讀的名稱 |
| `customAgents[0].description` | 自定義文字 | 描述代理程式的用途 |
| `customAgents[0].tools` | `["grep", "glob", "view"]` | 限制代理程式僅能使用唯讀工具 |
| `customAgents[0].prompt` | 自定義文字 | 設定代理程式的行為指令 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 執行檔（自動偵測或設定 `COPILOT_CLI_PATH`）和 `GITHUB_TOKEN`。
