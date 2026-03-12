# Stdio 傳輸範例

演示 **stdio** 傳輸模式的範例。SDK 將 `copilot` 作為子進程啟動，並使用 Content-Length 框架的 JSON-RPC 2.0 訊息透過標準輸入/輸出進行通訊。

```
┌─────────────┐   stdin/stdout (JSON-RPC)   ┌──────────────┐
│  您的應用程式  │ ──────────────────────────▶  │ Copilot CLI  │
│  (SDK)      │ ◀──────────────────────────  │ (子進程)      │
└─────────────┘                              └──────────────┘
```

每個範例都遵循相同的流程：

1. **建立一個用戶端**，自動啟動 `copilot`
2. 以 `gpt-4.1` 模型為目標 **開啟一個會話**
3. **發送提示詞** ("What is the capital of France?")
4. **列印回應** 並進行清理

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |
| `python/` | `github-copilot-sdk` | Python |
| `go/` | `github.com/github/copilot-sdk/go` | Go |

## 先決條件

- **Copilot CLI** — 設定 `COPILOT_CLI_PATH`
- **身份驗證** — 設定 `GITHUB_TOKEN`，或執行 `gh auth login`
- **Node.js 20+** (TypeScript 範例)
- **Python 3.10+** (Python 範例)
- **Go 1.24+** (Go 範例)

## 快速開始

**TypeScript**
```bash
cd typescript
npm install && npm run build && npm start
```

**Python**
```bash
cd python
pip install -r requirements.txt
python main.py
```

**Go**
```bash
cd go
go run main.go
```

## 驗證

```bash
./verify.sh
```

分兩個階段執行：

1. **建置 (Build)** — 安裝依賴項並編譯每個範例
2. **端對端執行 (E2E Run)** — 以 60 秒超時執行每個範例，並驗證其產生輸出
