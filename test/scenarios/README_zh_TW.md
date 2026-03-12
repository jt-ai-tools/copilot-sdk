# SDK E2E 場景測試

Copilot SDK 的端到端場景測試。每個場景都演示了特定的 SDK 能力，並提供 TypeScript、Python 和 Go 的實現。

## 結構

```
scenarios/
├── auth/           # 認證流程 (OAuth, BYOK, 令牌來源)
├── bundling/       # 部署架構 (stdio, TCP, 容器)
├── callbacks/      # 生命周期鉤子、權限、用戶輸入
├── modes/          # 預設模式 (CLI, 文件系統, 最小化)
├── prompts/        # 提示詞配置 (附件, 系統消息, 推理)
├── sessions/       # 會話管理 (流式傳輸, 恢復, 並發, 無限)
├── tools/          # 工具能力 (自定義代理, MCP, 技能, 過濾)
├── transport/      # 傳輸協議 (stdio, TCP, WASM, 重連)
└── verify.sh       # 運行所有場景
```

## 運行

運行所有場景：

```bash
COPILOT_CLI_PATH=/path/to/copilot GITHUB_TOKEN=$(gh auth token) bash verify.sh
```

運行單個場景：

```bash
COPILOT_CLI_PATH=/path/to/copilot GITHUB_TOKEN=$(gh auth token) bash <category>/<scenario>/verify.sh
```

## 前提條件

- **Copilot CLI** — 設置 `COPILOT_CLI_PATH`
- **GitHub 令牌** — 設置 `GITHUB_TOKEN` 或使用 `gh auth login`
- **Node.js 20+**, **Python 3.10+**, **Go 1.24+** (按語言)
