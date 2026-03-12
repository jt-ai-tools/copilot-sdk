# Copilot CLI 擴充功能

擴充功能為 Copilot CLI 新增自訂工具、Hook 和行為。它們作為獨立的 Node.js 程序執行，透過 stdio 與 CLI 透過 JSON-RPC 進行通訊。

## 擴充功能運作方式

```
┌─────────────────────┐          JSON-RPC / stdio           ┌──────────────────────┐
│   Copilot CLI        │ ◄──────────────────────────────────► │  擴充功能程序        │
│   (父程序)           │    工具呼叫、事件、Hook            │  (分支子程序)        │
│                      │                                      │                      │
│  • 發現擴充功能      │                                      │  • 註冊工具          │
│  • 分支程序          │                                      │  • 註冊 Hook          │
│  • 路由工具呼叫      │                                      │  • 接聽事件          │
│  • 管理生命週期      │                                      │  • 使用 SDK API      │
└─────────────────────┘                                      └──────────────────────┘
```

1. **發現**：CLI 會掃描 `.github/extensions/` (專案) 和使用者的 copilot 設定擴充功能目錄，尋找包含 `extension.mjs` 的子目錄。
2. **啟動**：每個擴充功能都作為一個子程序被分支，並透過自動模組解析器提供 `@github/copilot-sdk`。
3. **連線**：擴充功能呼叫 `joinSession()`，該函式會透過 stdio 建立到 CLI 的 JSON-RPC 連線，並附加到使用者目前的前景工作階段。
4. **註冊**：工作階段選項中宣告的工具和 Hook 會註冊到 CLI，並供代理使用。
5. **生命週期**：擴充功能會在 `/clear` (或如果前景工作階段被替換) 時重新載入，並在 CLI 退出 (SIGTERM，5 秒後 SIGKILL) 時停止。

## 檔案結構

```
.github/extensions/
  my-extension/
    extension.mjs      ← 進入點 (必填，必須是 .mjs)
```

- 僅支援 `.mjs` 檔案 (ES 模組)。檔案必須命名為 `extension.mjs`。
- 每個擴充功能都位於自己的子目錄中。
- `@github/copilot-sdk` 匯入會自動解析 —— 您無需安裝它。

## SDK

擴充功能使用 `@github/copilot-sdk` 與 CLI 進行所有互動：

```js
import { approveAll } from "@github/copilot-sdk";
import { joinSession } from "@github/copilot-sdk/extension";

const session = await joinSession({
    onPermissionRequest: approveAll,
    tools: [
        /* ... */
    ],
    hooks: {
        /* ... */
    },
});
```

`session` 物件提供了發送訊息、記錄到時間軸、接聽事件以及存取 RPC API 的方法。有關完整的類型資訊，請參閱 SDK 套件中的 `.d.ts` 檔案。

## 延伸閱讀

- `examples_zh_TW.md` — 工具、Hook、事件和完整擴充功能的實用程式碼範例
- `agent-author_zh_TW.md` — 代理程式化編寫擴充功能的逐步工作流
