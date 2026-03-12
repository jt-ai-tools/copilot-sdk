# 設定範例：工具覆寫 (Tool Overrides)

示範如何使用 `overridesBuiltInTool` 旗標，以自定義實作來覆寫內建工具。當在自定義工具上設定此旗標時，SDK 會知道要停用對應的內建工具，從而改用您的實作。

## 每個範例的功能

1. 建立一個包含自定義 `grep` 工具（已啟用 `overridesBuiltInTool`）的工作階段，該工具會回傳 `"CUSTOM_GREP_RESULT: <query>"`。
2. 發送：_"使用 grep 搜尋 'hello' 這個字"_。
3. 列印回應 — 應包含 `CUSTOM_GREP_RESULT`（證明執行的是自定義工具而非內建工具）。

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `tools` | 自定義 `grep` 工具 | 提供自定義的 grep 實作 |
| `overridesBuiltInTool` | `true` | 指示 SDK 停用內建 `grep` 以改用自定義的工具 |

此旗標在 TypeScript (`overridesBuiltInTool: true`)、Python (`overrides_built_in_tool=True`) 和 Go (`OverridesBuiltInTool: true`) 中是針對每個工具進行設定。在 C# 中，請透過 `AIFunctionFactoryOptions` 在工具的 `AdditionalProperties` 中設定 `is_override`。

## 執行

```bash
./verify.sh
```

需要 `copilot` 執行檔（自動偵測或設定 `COPILOT_CLI_PATH`）和 `GITHUB_TOKEN`。

## 驗證

驗證指令碼會檢查：
- 回應包含 `CUSTOM_GREP_RESULT`（自定義工具已被叫用）。
- 回應**不**包含典型的內建 grep 輸出模式。
