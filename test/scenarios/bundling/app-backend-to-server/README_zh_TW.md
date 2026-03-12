# App-Backend-to-Server 範例

這些範例展示了 Copilot SDK 的 **app-backend-to-server** 部署架構。在此情境中，網頁後端連接到一個**預先執行**的 `copilot` TCP 伺服器，並公開一個 `POST /chat` HTTP 端點。HTTP 伺服器從用戶端接收提示詞（prompt），將其轉發給 Copilot CLI，並返回回應。

```
┌────────┐   HTTP POST /chat   ┌─────────────┐   TCP (JSON-RPC)   ┌──────────────┐
│ 用戶端  │ ──────────────────▶  │ 網頁後端     │ ─────────────────▶  │ Copilot CLI  │
│ (curl) │ ◀──────────────────  │ (HTTP 伺服器)│ ◀─────────────────  │ (TCP 伺服器) │
└────────┘                      └─────────────┘                     └──────────────┘
```

每個範例都遵循相同的流程：

1. **啟動**一個具有 `POST /chat` 端點的 HTTP 伺服器
2. **接收**一個 JSON 請求 `{ "prompt": "..." }`
3. **連接**到透過 TCP 執行的 `copilot` 伺服器
4. **開啟一個工作階段（session）**，目標為 `gpt-4.1` 模型
5. **轉發提示詞**並收集回應
6. **返回**一個 JSON 回應 `{ "response": "..." }`

## 語言

| 目錄 | SDK / 方法 | 語言 | HTTP 框架 |
|-----------|---------------|----------|----------------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) | Express |
| `python/` | `github-copilot-sdk` | Python | Flask |
| `go/` | `github.com/github/copilot-sdk/go` | Go | net/http |

## 先決條件

- **Copilot CLI** — 設定 `COPILOT_CLI_PATH`
- **身份驗證** — 設定 `GITHUB_TOKEN`，或執行 `gh auth login`
- **Node.js 20+** (TypeScript 範例)
- **Python 3.10+** (Python 範例)
- **Go 1.24+** (Go 範例)

## 啟動伺服器

在執行任何範例之前，請將 `copilot` 作為 TCP 伺服器啟動：

```bash
copilot --port 3000 --headless --auth-token-env GITHUB_TOKEN
```

## 快速入門

**TypeScript**
```bash
cd typescript
npm install && npm run build
CLI_URL=localhost:3000 npm start
# 在另一個終端機中：
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is the capital of France?"}'
```

**Python**
```bash
cd python
pip install -r requirements.txt
CLI_URL=localhost:3000 python main.py
# 在另一個終端機中：
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is the capital of France?"}'
```

**Go**
```bash
cd go
CLI_URL=localhost:3000 go run main.go
# 在另一個終端機中：
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is the capital of France?"}'
```

所有範例預設使用 `localhost:3000` 連接 Copilot CLI，並將 HTTP 伺服器連接埠設為 `8080`。可使用 `CLI_URL`（或 `COPILOT_CLI_URL`）和 `PORT` 環境變數進行覆寫：

```bash
CLI_URL=localhost:4000 PORT=9090 npm start
```

## 驗證

隨附一個腳本，可啟動伺服器、進行建置，並對每個範例執行端對端測試：

```bash
./verify.sh
```

它分三個階段執行：

1. **伺服器** — 在隨機連接埠上啟動 `copilot`
2. **建置** — 安裝依賴項並編譯每個範例
3. **E2E 執行** — 啟動每個 HTTP 伺服器，透過 curl 發送 `POST /chat` 請求，並驗證其是否返回回應

腳本結束後，伺服器會自動停止。
