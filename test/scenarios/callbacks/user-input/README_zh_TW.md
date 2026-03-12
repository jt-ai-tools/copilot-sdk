# 配置範例：使用者輸入請求 (User Input Request)

演示 **使用者輸入請求流程** — 執行階段的 `ask_user` 工具會觸發 SDK 的回呼 (callback)，讓主機應用程式能夠以程式化的方式回應代理程式的問題，而不需要人工互動。

此模式適用於：
- **自動化管道**：答案已預先確定或從配置中獲取
- **自訂 UI**：攔截使用者輸入請求並顯示其自有的對話框
- **測試**：需要使用者互動的代理程式流程

## 運作方式

1. 在工作階段上 **啟用 `onUserInputRequest` 回呼**
2. 每當代理程式透過 `ask_user` 提出問題時，回呼會自動回應 `"Paris"`
3. **傳送提示**，指示代理程式使用 `ask_user` 來詢問使用者對哪個城市感興趣
4. 代理程式收到 `"Paris"` 作為答案並告訴我們相關資訊
5. 列印回應並透過記錄確認使用者輸入流程已成功運作

## 配置

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `onUserInputRequest` | 回傳 `{ answer: "Paris", wasFreeform: true }` | 自動回應 `ask_user` 工具呼叫 |
| `onPermissionRequest` | 自動核准 | 無權限對話框 |
| `hooks.onPreToolUse` | 自動允許 | 無工具確認提示 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進位檔案 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
