# Container-Proxy 範例

在 Docker 容器內執行 Copilot CLI，並在主機上使用一個簡單的代理伺服器（proxy）來返回預設回應。這展示了一種部署模式：由外部服務攔截代理程式（agent）的 LLM 呼叫 — 在實際生產環境中，代理伺服器會加入憑證並轉發給真正的提供者；在此範例中，它僅返回一個固定回覆作為概念驗證（proof-of-concept）。

```
  主機
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ┌─────────────┐                                     │
│  │ 應用程式     │   TCP :3000                         │
│  │ (SDK)       │ ────────────────┐                   │
│  └─────────────┘                 │                   │
│                                  ▼                   │
│                    ┌──────────────────────────┐       │
│                    │  Docker 容器             │       │
│                    │  Copilot CLI             │       │
│                    │  --port 3000 --headless  │       │
│                    │  --bind 0.0.0.0          │       │
│                    │  --auth-token-env        │       │
│                    └────────────┬─────────────┘       │
│                                │                     │
│                   HTTP 指向 host.docker.internal:4000 │
│                                │                     │
│                    ┌───────────▼──────────────┐       │
│                    │  proxy.py                │       │
│                    │  (連接埠 4000)             │       │
│                    │  返回預設回應               │       │
│                    └─────────────────────────-┘       │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## 為什麼使用這種模式？

代理程式執行環境（Copilot CLI）**無法存取 API 金鑰**。所有 LLM 流量都透過主機上的代理伺服器進行。在實際生產環境中，您會將 `proxy.py` 替換為真正的代理伺服器，該伺服器會植入憑證並轉發給 OpenAI/Anthropic 等。這意味著：

- **映像檔中無秘密資訊** — 可安全地分享、掃描並部署到任何地方
- **執行時無秘密資訊** — 即使容器遭到入侵，也沒有可供竊取的權杖（token）
- **自由切換提供者** — 無需重新建置容器即可更改代理目標
- **集中式金鑰管理** — 一個代理伺服器即可管理所有代理程式/服務的金鑰

## 先決條件

- 具備 Docker Compose 的 **Docker**
- **Python 3**（用於代理伺服器 — 僅使用標準函式庫，無需安裝 pip）

## 設定

### 1. 啟動代理伺服器

```bash
python3 proxy.py 4000
```

這會在連接埠 4000 上啟動一個極簡的 OpenAI 相容 HTTP 伺服器，並針對每個請求返回預設的 "The capital of France is Paris." 回應。

### 2. 在 Docker 中啟動 Copilot CLI

```bash
docker compose up -d --build
```

這會從原始碼建置 Copilot CLI 並在連接埠 3000 上啟動它。它會將 LLM 請求發送到 `host.docker.internal:4000` — 容器內不會傳入任何 API 金鑰。

### 3. 執行用戶端範例

**TypeScript**
```bash
cd typescript && npm install && npm run build && npm start
```

**Python**
```bash
cd python && pip install -r requirements.txt && python main.py
```

**Go**
```bash
cd go && go run main.go
```

所有範例預設連接到 `localhost:3000`。可使用 `COPILOT_CLI_URL` 進行覆寫。

## 驗證

端對端執行所有範例：

```bash
chmod +x verify.sh
./verify.sh
```

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |
| `python/` | `github-copilot-sdk` | Python |
| `go/` | `github.com/github/copilot-sdk/go` | Go |

## 運作原理

1. **Copilot CLI** 在 Docker 中啟動，並設定 `COPILOT_API_URL=http://host.docker.internal:4000` — 這會覆寫預設的 Copilot API 端點，使其指向代理伺服器
2. 當代理程式需要呼叫 LLM 時，它會向代理伺服器發送標準的 OpenAI 格式請求
3. **proxy.py** 接收請求並返回預設回應（在實際生產環境中，這會植入憑證並轉發給真正的提供者）
4. 回應流程為：代理伺服器 → Copilot CLI → 您的應用程式

容器永遠不會看到或需要任何 API 憑證。
