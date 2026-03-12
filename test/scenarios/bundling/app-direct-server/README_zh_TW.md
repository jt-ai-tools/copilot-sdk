# App-Direct-Server 範例

這些範例展示了 Copilot SDK 的 **app-direct-server** 部署架構。在此情境中，SDK 連接到一個**預先執行**的 `copilot` TCP 伺服器 — 應用程式不會啟動或管理該伺服器程序。

```
┌─────────────┐   TCP (JSON-RPC)   ┌──────────────┐
│ 應用程式     │ ─────────────────▶  │ Copilot CLI  │
│ (SDK)       │ ◀─────────────────  │ (TCP 伺服器) │
└─────────────┘                     └──────────────┘
```

每個範例都遵循相同的流程：

1. **連接**到透過 TCP 執行的 `copilot` 伺服器
2. **開啟一個工作階段（session）**，目標為 `gpt-4.1` 模型
3. **發送提示詞**（"What is the capital of France?"）
4. **列印回應**並進行清理

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

在執行任何範例之前，請將 `copilot` 作為 TCP 伺服器啟動：

```bash
copilot --port 3000 --headless --auth-token-env GITHUB_TOKEN
```

## 快速入門

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

所有範例預設使用 `localhost:3000`。可使用 `COPILOT_CLI_URL` 環境變數進行覆寫：

```bash
COPILOT_CLI_URL=localhost:8080 npm start
```

## 驗證

隨附一個腳本，可啟動伺服器、進行建置，並對每個範例執行端對端測試：

```bash
./verify.sh
```

它分三個階段執行：

1. **伺服器** — 在隨機連接埠上啟動 `copilot`（從伺服器輸出自動偵測）
2. **建置** — 安裝依賴項並編譯每個範例
3. **E2E 執行** — 執行每個範例（超時時間為 60 秒），並驗證其是否產生輸出

腳本結束後，伺服器會自動停止。
