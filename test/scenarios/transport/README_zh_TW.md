# 傳輸範例

按 **傳輸模式** 組織的極簡範例 —— 與 `copilot` 通訊使用的通訊協定。每個子資料夾都使用相同的 "What is the capital of France?" 流程演示一種傳輸方式。

## 傳輸模式

| 傳輸 | 描述 | 語言 |
|-----------|-------------|-----------|
| **[stdio](stdio/README_zh_TW.md)** | SDK 將 `copilot` 作為子進程啟動，並透過 stdin/stdout 進行通訊 | TypeScript, Python, Go |
| **[tcp](tcp/README_zh_TW.md)** | SDK 連接到預先運行的 `copilot` TCP 伺服器 | TypeScript, Python, Go |
| **[wasm](wasm/)** | SDK 將 `copilot` 作為進程內的 WASM 模組載入 | TypeScript |

## 它們有何不同

| | stdio | tcp | wasm |
|---|---|---|---|
| **進程模型** | 子進程 | 外部伺服器 | 進程內 |
| **需要的二進制檔案** | 是 (自動啟動) | 是 (預先啟動) | 否 (WASM 模組) |
| **有線協議** | 管道上的 Content-Length 框架 JSON-RPC | TCP 上的 Content-Length 框架 JSON-RPC | 記憶體內函式呼叫 |
| **最適用於** | CLI 工具、桌面應用程式 | 共享伺服器、多租戶 | 無伺服器 (Serverless)、邊緣運算 (Edge)、沙盒環境 |

## 先決條件

- **身份驗證** — 設定 `GITHUB_TOKEN`，或執行 `gh auth login`
- **Copilot CLI** — stdio 和 tcp 需要 (設定 `COPILOT_CLI_PATH`)
- 根據需要準備語言工具鏈 (Node.js 20+, Python 3.10+, Go 1.24+)

## 驗證

每種傳輸方式都有自己的 `verify.sh`，用於建置並執行所有語言範例：

```bash
cd stdio && ./verify.sh
cd tcp   && ./verify.sh
cd wasm  && ./verify.sh
```
