# 認證範例：BYOK OpenAI

本範例展示了如何以 **BYOK** 模式配合 OpenAI 兼容提供者使用 Copilot SDK。

## 本範例的作用

1. 使用自定義提供者 (`type: "openai"`) 創建會話
2. 使用您的 `OPENAI_API_KEY` 而非 GitHub 認證
3. 發送提示詞並打印響應

## 前提條件

- `copilot` 二進制文件 (`COPILOT_CLI_PATH`，或由 SDK 自動檢測)
- Node.js 20+
- `OPENAI_API_KEY`

## 運行

```bash
cd typescript
npm install --ignore-scripts
npm run build
OPENAI_API_KEY=sk-... node dist/index.js
```

可選環境變量：

- `OPENAI_BASE_URL` (默認值：`https://api.openai.com/v1`)
- `OPENAI_MODEL` (默認值：`gpt-4.1-mini`)

## 驗證

```bash
./verify.sh
```

默認運行構建檢查。E2E 運行是可選的，需要同時設置 `BYOK_SAMPLE_RUN_E2E=1` 和 `OPENAI_API_KEY`。
