# 認證範例：BYOK Ollama (壓縮上下文)

本範例展示了如何使用 **本地 Ollama** 進行 BYOK，並刻意修剪會話上下文，使其在較小的本地模型上運行效果更好。

## 本範例的作用

1. 使用指向 Ollama (`http://localhost:11434/v1`) 的自定義提供者
2. 將默認系統提示詞替換為簡短的壓縮提示詞
3. 設置 `availableTools: []` 以從模型上下文中移除內置工具定義
4. 發送提示詞並打印響應

這將創建一個適用於受限上下文窗口的小型助手配置。

## 前提條件

- `copilot` 二進制文件 (`COPILOT_CLI_PATH`，或由 SDK 自動檢測)
- Node.js 20+
- 本地運行的 Ollama (`ollama serve`)
- 已下載本地模型 (例如：`ollama pull llama3.2:3b`)

## 運行

```bash
cd typescript
npm install --ignore-scripts
npm run build
node dist/index.js
```

可選環境變量：

- `OLLAMA_BASE_URL` (默認值：`http://localhost:11434/v1`)
- `OLLAMA_MODEL` (默認值：`llama3.2:3b`)

## 驗證

```bash
./verify.sh
```

默認運行構建檢查。E2E 運行是可選的，需要設置 `BYOK_SAMPLE_RUN_E2E=1`。
