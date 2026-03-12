# configs/hooks — 工作階段生命週期掛鉤 (Session Lifecycle Hooks)

演示在典型的 提示–工具–回應 (prompt–tool–response) 週期中觸發的所有 SDK 工作階段生命週期掛鉤。

## 已測試的掛鉤

| 掛鉤 | 觸發時機 | 目的 |
|------|---------------|---------|
| `onSessionStart` | 工作階段建立時 | 初始化記錄、指標或狀態 |
| `onSessionEnd` | 工作階段銷毀時 | 清理資源、排空 (flush) 記錄 |
| `onPreToolUse` | 工具執行前 | 核准/拒絕工具呼叫、稽核使用情況 |
| `onPostToolUse` | 工具執行後 | 記錄結果、收集指標 |
| `onUserPromptSubmitted` | 使用者傳送提示時 | 轉換、驗證或記錄提示 |
| `onErrorOccurred` | 發生錯誤時 | 集中式錯誤處理 |

## 此情境的操作內容

1. 建立一個註冊了 **所有** 生命週期掛鉤的工作階段。
2. 每個掛鉤在被調用時會將其名稱附加到記錄清單中。
3. 傳送一個會觸發工具使用 (glob 檔案列出) 的提示。
4. 列印模型的建議回應，接著列出掛鉤執行記錄，顯示哪些掛鉤被觸發以及觸發順序。

## 執行

```bash
# TypeScript
cd typescript && npm install && npm run build && node dist/index.js

# Python
cd python && pip install -r requirements.txt && python3 main.py

# Go
cd go && go run .
```

## 全部驗證

```bash
./verify.sh
```
