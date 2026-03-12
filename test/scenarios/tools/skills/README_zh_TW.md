# 設定範例：技能 (SKILL.md 探索)

示範如何設定 Copilot SDK 使用包含 `SKILL.md` 檔案的**技能目錄**。代理程式在執行時會探索並使用這些 Markdown 檔案中定義的技能。

## 測試內容

1. **技能探索** — 設定 `skillDirectories` 將代理程式指向包含定義可用技能的 `SKILL.md` 檔案目錄。
2. **技能執行** — 當被要求使用技能時，代理程式會讀取技能定義並遵循其指令。
3. **SKILL.md 格式** — 技能被定義為包含名稱、描述和使用指令的 Markdown 檔案。

## SKILL.md 格式

`SKILL.md` 檔案是放置在技能根目錄下的具名目錄中的 Markdown 文件：

```
sample-skills/
└── greeting/
    └── SKILL.md      # 定義 "greeting" 技能
```

該檔案包含：
- **標題** (`# skill-name`) — 技能的識別碼
- **描述** — 技能的功能
- **用法** — 代理程式在叫用技能時遵循的指令

## 每個範例的功能

1. 建立一個 `skillDirectories` 指向 `sample-skills/` 的工作階段。
2. 發送：_"使用 greeting 技能向名為 Alice 的人打招呼。"_
3. 代理程式從 `SKILL.md` 探索 greeting 技能並生成個人化的問候語。
4. 列印回應並確認技能目錄設定。

## 設定

| 選項 | 值 | 效果 |
|--------|-------|--------|
| `skillDirectories` | `["path/to/sample-skills"]` | 將代理程式指向包含技能定義的目錄 |

## 執行

```bash
./verify.sh
```

需要 `copilot` 執行檔（自動偵測或設定 `COPILOT_CLI_PATH`）和 `GITHUB_TOKEN`。
