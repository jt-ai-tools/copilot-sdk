# 身份驗證範例：BYOK Azure OpenAI

本範例展示如何在 **BYOK** 模式下，搭配 Azure OpenAI 提供者使用 Copilot SDK。

## 本範例的作用

1. 使用自定義提供者（`type: "azure"`）建立一個工作階段（session）
2. 使用您的 Azure OpenAI 端點和 API 金鑰，而非 GitHub 身份驗證
3. 設定 Azure 特有的 `apiVersion` 欄位
4. 發送提示詞（prompt）並列印回應

## 先決條件

- `copilot` 二進位檔案（`COPILOT_CLI_PATH`，或由 SDK 自動偵測）
- Node.js 20+
- 已部署模型的 Azure OpenAI 資源

## 執行

```bash
cd typescript
npm install --ignore-scripts
npm run build
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com AZURE_OPENAI_API_KEY=... node dist/index.js
```

### 環境變數

| 變數 | 是否必填 | 預設值 | 說明 |
|---|---|---|---|
| `AZURE_OPENAI_ENDPOINT` | 是 | — | Azure OpenAI 資源端點 URL |
| `AZURE_OPENAI_API_KEY` | 是 | — | Azure OpenAI API 金鑰 |
| `AZURE_OPENAI_MODEL` | 否 | `gpt-4.1` | 部署 / 模型名稱 |
| `AZURE_API_VERSION` | 否 | `2024-10-21` | Azure OpenAI API 版本 |
| `COPILOT_CLI_PATH` | 否 | 自動偵測 | `copilot` 二進位檔案路徑 |

## 提供者設定

與標準 OpenAI BYOK 的主要區別在於提供者設定中的 `azure` 區塊：

```typescript
provider: {
  type: "azure",
  baseUrl: endpoint,
  apiKey,
  azure: {
    apiVersion: "2024-10-21",
  },
}
```

## 驗證

```bash
./verify.sh
```

預設執行建置檢查。執行端對端（E2E）測試需要設定 `AZURE_OPENAI_ENDPOINT` 和 `AZURE_OPENAI_API_KEY`。
