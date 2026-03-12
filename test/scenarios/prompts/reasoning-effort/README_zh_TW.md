# 設定範例：推理努力 (Reasoning Effort)

示範如何為 Copilot SDK 設定不同的 **推理努力 (reasoning effort)** 層級。`reasoningEffort` 工作階段設定控制模型在回應前投入多少運算資源進行思考。

## 推理努力層級

| 層級 | 效果 |
|-------|--------|
| `low` | 回應最快，推理最少 |
| `medium` | 速度與深度的平衡 |
| `high` | 推理更深，回應更慢 |
| `xhigh` | 最大的推理努力 |

## 此範例的操作內容

1. 建立一個具有 `reasoningEffort: "low"` 且 `availableTools: []` 的工作階段
2. 發送：_"法國的首都是哪裡？"_
3. 列印回應 —— 確認模型在低努力層級下能正確回應

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `reasoningEffort` | `"low"` | 設定最小推理努力 |
| `availableTools` | `[]` (空陣列) | 移除所有內建工具 |
| `systemMessage.mode` | `"replace"` | 取代預設系統提示 |
| `systemMessage.content` | 自訂簡潔提示 | 指示代理簡潔地回答 |

## 語言

| 目錄 | SDK / 方法 | 語言 |
|-----------|---------------|----------|
| `typescript/` | `@github/copilot-sdk` | TypeScript (Node.js) |
| `python/` | `github-copilot-sdk` | Python |
| `go/` | `github.com/github/copilot-sdk/go` | Go |

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進位檔案 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
