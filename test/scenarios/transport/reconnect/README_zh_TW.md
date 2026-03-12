# TCP 重連範例

測試一個 **預先運行** 的 `copilot` TCP 伺服器是否能正確處理 **多個連續會話**。SDK 會連接、建立會話、交換訊息、銷毀會話，然後重複此過程 —— 驗證伺服器在整個會話生命週期中保持回應。

```
┌─────────────┐   TCP (JSON-RPC)   ┌──────────────┐
│  您的應用程式  │ ─────────────────▶  │ Copilot CLI  │
│  (SDK)      │ ◀─────────────────  │ (TCP 伺服器)  │
└─────────────┘                     └──────────────┘
     會話 1：建立 → 發送 → 斷開
     會話 2：建立 → 發送 → 斷開
```

## 測試內容

- TCP 伺服器在之前的會話銷毀後接受新的會話
- 伺服器狀態在會話之間被正確清理
- SDK 用戶端可以為多個會話生命週期重複使用相同的連接
- 在連續會話中沒有資源洩漏或連接埠衝突

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |

> **僅限 TypeScript：** 此場景測試 TCP 上的 SDK 級別會話生命週期。重連行為是 SDK 的關注點，因此只需要一種語言來驗證它。

## 先決條件

- **Copilot CLI** — 設定 `COPILOT_CLI_PATH`
- **身份驗證** — 設定 `GITHUB_TOKEN`，或執行 `gh auth login`
- **Node.js 20+** (TypeScript 範例)

## 快速開始

啟動 TCP 伺服器：

```bash
copilot --port 3000 --headless --auth-token-env GITHUB_TOKEN
```

執行範例：

```bash
cd typescript
npm install && npm run build
COPILOT_CLI_URL=localhost:3000 npm start
```

## 驗證

```bash
./verify.sh
```

分三個階段執行：

1. **伺服器 (Server)** — 將 `copilot` 作為 TCP 伺服器啟動（自動偵測連接埠）
2. **建置 (Build)** — 安裝依賴項並編譯 TypeScript 範例
3. **端對端執行 (E2E Run)** — 以 120 秒超時執行範例，驗證兩個會話均已完成並列印 "Reconnect test passed"

腳本退出時，伺服器會自動停止。
