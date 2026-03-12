# Fully-Bundled 範例

這些自帶環境（self-contained）的範例展示了 Copilot SDK 的 **fully-bundled** 部署架構。在此情境中，SDK 會透過 stdio 將 `copilot` 作為子程序啟動 — 不需要外部伺服器或容器。

每個範例都遵循相同的流程：

1. **建立用戶端**，自動啟動 `copilot`
2. **開啟一個工作階段（session）**，目標為 `gpt-4.1` 模型
3. **發送提示詞**（"What is the capital of France?"）
4. **列印回應**並進行清理

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |
| `typescript-wasm/` | 使用 WASM 執行階段的 `@github/copilot-sdk` | TypeScript (Node.js) |
| `python/` | `github-copilot-sdk` | Python |
| `go/` | `github.com/github/copilot-sdk/go` | Go |

## 先決條件

- **Copilot CLI** — 設定 `COPILOT_CLI_PATH`
- **身份驗證** — 設定 `GITHUB_TOKEN`，或執行 `gh auth login`
- **Node.js 20+** (TypeScript 範例)
- **Python 3.10+** (Python 範例)
- **Go 1.24+** (Go 範例)

## 快速入門

**TypeScript**
```bash
cd typescript
npm install && npm run build && npm start
```

**TypeScript (WASM)**
```bash
cd typescript-wasm
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

隨附一個腳本，可建置並對每個範例執行端對端測試：

```bash
./verify.sh
```

它分兩個階段執行：

1. **建置** — 安裝依賴項並編譯每個範例
2. **E2E 執行** — 執行每個範例（超時時間為 60 秒），並驗證其是否產生輸出

如果 `copilot` 二進位檔案不在預設位置，請設定 `COPILOT_CLI_PATH` 指向該檔案。
