# 設定範例：檔案附件

示範如何在使用 Copilot SDK 時，在提示中發送 **檔案附件**。這驗證了 SDK 能正確將檔案內容傳遞給模型，且模型能在回應中引用該內容。

## 此範例的操作內容

1. 在 `replace` 模式下使用自訂系統提示建立工作階段
2. 解析 `sample-data.txt` 的路徑 (該檔案為情境根目錄中的小型文字檔)
3. 發送：_"隨附檔案中列出了哪些語言？"_ 並將該檔案作為附件發送
4. 列印回應 —— 回應應列出 TypeScript、Python 和 Go

## 附件格式

| 欄位 | 值 | 描述 |
|-------|-------|-------------|
| `type` | `"file"` | 指示本地檔案附件 |
| `path` | 檔案的絕對路徑 | SDK 讀取並將檔案內容發送給模型 |

### 特定語言用法

| 語言 | 附件語法 |
|----------|------------------|
| TypeScript | `attachments: [{ type: "file", path: sampleFile }]` |
| Python | `"attachments": [{"type": "file", "path": sample_file}]` |
| Go | `Attachments: []copilot.Attachment{{Type: "file", Path: sampleFile}}` |

## 範例資料

`sample-data.txt` 檔案包含作為附件目標的基本專案中繼資料：

```
專案：Copilot SDK 範例
版本：1.0.0
描述：示範 Copilot SDK 的最小可建置範例
語言：TypeScript, Python, Go
```

## 執行

```bash
./verify.sh
```

需要 `copilot` 二進位檔案 (自動偵測或設定 `COPILOT_CLI_PATH`) 和 `GITHUB_TOKEN`。
