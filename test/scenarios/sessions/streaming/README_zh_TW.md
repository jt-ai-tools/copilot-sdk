# 設定範例：串流 (Streaming)

示範如何為 Copilot SDK 設定 **`streaming: true`** 以接收增量回應區塊。這驗證了伺服器在發送最終的 `assistant.message` 事件之前，會發送多個 `assistant.message_delta` 事件。

## 每個範例的操作內容

1. 建立一個具有 `streaming: true` 的工作階段
2. 註冊一個事件接聽程式來計算 `assistant.message_delta` 事件的數量
3. 發送：_"法國的首都是哪裡？"_
4. 列印最終回應以及收到的串流區塊數量

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `streaming` | `true` | 啟用增量串流 —— 伺服器會在產生權杖時發出 `assistant.message_delta` 事件 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進位檔案 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
