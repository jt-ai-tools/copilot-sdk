# TCP 傳輸範例

演示 **TCP** 傳輸模式的範例。SDK 透過 TCP 套接字（Socket）使用 Content-Length 框架的 JSON-RPC 2.0 訊息連接到 **預先運行** 的 `copilot` TCP 伺服器。

```
┌─────────────┐   TCP (JSON-RPC)   ┌──────────────┐
│  您的應用程式  │ ─────────────────▶  │ Copilot CLI  │
│  (SDK)      │ ◀─────────────────  │ (TCP 伺服器)  │
└─────────────┘                     └──────────────┘
```

每個範例都遵循相同的流程：

1. 透過 TCP **連接** 到運行中的 `copilot` 伺服器
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

## 啟動伺服器

在執行任何範例之前，將 `copilot` 作為 TCP 伺服器啟動：

```bash
copilot --port 3000 --headless --auth-token-env GITHUB_TOKEN
```

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

所有範例預設為 `localhost:3000`。可透過 `COPILOT_CLI_URL` 環境變數覆蓋：

```bash
COPILOT_CLI_URL=localhost:8080 npm start
```

## 驗證

```bash
./verify.sh
```

分三個階段執行：

1. **伺服器 (Server)** — 將 `copilot` 作為 TCP 伺服器啟動（自動偵測連接埠）
2. **建置 (Build)** — 安裝依賴項並編譯每個範例
3. **端對端執行 (E2E Run)** — 以 60 秒超時執行每個範例，並驗證其產生輸出

腳本退出時，伺服器會自動停止。
