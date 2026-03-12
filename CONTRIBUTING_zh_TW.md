## 貢獻指南 (Contributing)

[fork]: https://github.com/github/copilot-sdk/fork
[pr]: https://github.com/github/copilot-sdk/compare

你好！我們很高興您想為這個專案做出貢獻。您的幫助對於保持這個專案的優秀至關重要。

對本專案的貢獻將根據[專案的開源授權](LICENSE)向公眾[發佈](https://help.github.com/articles/github-terms-of-service/#6-contributions-under-repository-license)。

請注意，本專案發佈時附帶了[貢獻者行為準則](CODE_OF_CONDUCT_zh_TW.md)。參與本專案即表示您同意遵守其條款。

## 我們正在尋找的貢獻類型

我們非常希望您能在以下方面提供幫助：

 * 修復現有功能集中的任何 bug
 * 使各個受支援語言的 SDK 更加符合該語言的習慣 (idiomatic) 且易於使用
 * 改進文件

如果您有全新功能的想法，請提交 issue 或發起討論。我們對新功能持非常開放的態度，但需要確保它們與底層 Copilot CLI 的發展方向一致，並且可以在我們支援的所有語言中保持同步維護。

目前**我們不打算新增其他語言的 SDK**。如果您想為其他語言建立 Copilot SDK，我們很樂意聽取您的意見，並且我們可能會在我們的倉庫中提供指向您的 SDK 的連結。然而，短期內我們不計劃在此倉庫中新增更多特定語言的 SDK，因為我們需要保留維護能力，以便與現有的語言集一起快速前進。因此，對於任何其他語言，請考慮運行您自己的外部專案。

## 執行與測試程式碼的前置作業

這是一個多語言 SDK 倉庫。請安裝您打算開發的 SDK 所需的工具：

### 所有 SDK
1. (選用) 為方便起見，請安裝 [just](https://github.com/casey/just) 指令執行器

### Node.js/TypeScript SDK
1. 安裝 [Node.js](https://nodejs.org/) (v18+)
1. 安裝相依項目：`cd nodejs && npm ci`

### Python SDK
1. 安裝 [Python 3.8+](https://www.python.org/downloads/)
1. 安裝 [uv](https://github.com/astral-sh/uv)
1. 安裝相依項目：`cd python && uv pip install -e ".[dev]"`

### Go SDK
1. 安裝 [Go 1.24+](https://go.dev/doc/install)
1. 安裝 [golangci-lint](https://golangci-lint.run/welcome/install/#local-installation)
1. 安裝相依項目：`cd go && go mod download`

### .NET SDK
1. 安裝 [.NET 8.0+](https://dotnet.microsoft.com/download)
1. 安裝 [Node.js](https://nodejs.org/) (v18+) (.NET 測試依賴於基於 TypeScript 的測試工具)
1. 安裝 npm 相依項目 (從倉庫根目錄)：
   ```bash
   cd nodejs && npm ci
   cd test/harness && npm ci
   ```
1. 安裝 .NET 相依項目：`cd dotnet && dotnet restore`

## 提交提取請求 (Pull Request)

1. [Fork][fork] 並複製 (clone) 倉庫
1. 為您要修改的 SDK 安裝相依項目（見上文）
1. 確保測試在您的機器上通過（見下文指令）
1. 確保 Linter 在您的機器上通過（見下文指令）
1. 建立一個新分支：`git checkout -b my-branch-name`
1. 進行更改，新增測試，並確保測試和 Linter 仍然通過
1. 推送到您的 fork 並[提交提取請求 (Pull Request)][pr]
1. 為自己鼓掌，並等待您的提取請求被審核和合併。

### 執行測試與 Linter

如果您安裝了 `just`，您可以使用它來執行所有 SDK 或特定語言的測試和 Linter：

```bash
# 所有 SDK
just test          # 執行所有測試
just lint          # 執行所有 Linter
just format        # 格式化所有程式碼

# 個別 SDK
just test-nodejs   # Node.js 測試
just test-python   # Python 測試
just test-go       # Go 測試
just test-dotnet   # .NET 測試

just lint-nodejs   # Node.js Linting
just lint-python   # Python Linting
just lint-go       # Go Linting
just lint-dotnet   # .NET Linting
```

或者在每個 SDK 目錄中直接執行指令：

```bash
# Node.js
cd nodejs && npm test && npm run lint

# Python
cd python && uv run pytest && uv run ruff check .

# Go
cd go && go test ./... && golangci-lint run ./...

# .NET
cd dotnet && dotnet test test/GitHub.Copilot.SDK.Test.csproj
```

以下是一些可以增加您的提取請求被接受可能性的做法：

- 撰寫測試。
- 盡可能保持更改內容的專注。如果您想進行多個互不依賴的更改，請考慮將它們作為單獨的提取請求提交。
- 撰寫[良好的提交訊息](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)。

## 資源

- [如何為開源做貢獻](https://opensource.guide/how-to-contribute/)
- [使用提取請求 (Pull Requests)](https://help.github.com/articles/about-pull-requests/)
- [GitHub 說明](https://help.github.com)
