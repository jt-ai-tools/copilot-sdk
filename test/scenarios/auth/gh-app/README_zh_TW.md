# 認證範例：GitHub OAuth App (場景 1)

此場景演示了封裝好的應用程序如何讓終端用戶使用 GitHub OAuth 設備流程登錄，然後使用該用戶令牌配合他們自己的訂閱來調用 Copilot。

## 本範例的作用

1. 啟動 GitHub OAuth 設備流程
2. 提示用戶打開驗證網址並輸入代碼
3. 輪詢獲取訪問令牌
4. 獲取已登錄用戶的個人資料
5. 使用該 OAuth 令牌調用 Copilot (TypeScript/Python/Go 中的 SDK 客戶端)

## 前提條件

- GitHub OAuth App 客戶端 ID (`GITHUB_OAUTH_CLIENT_ID`)
- `copilot` 二進制文件 (`COPILOT_CLI_PATH`，或由 SDK 自動檢測)
- Node.js 20+
- Python 3.10+
- Go 1.24+

## 運行

### TypeScript

```bash
cd typescript
npm install --ignore-scripts
npm run build
GITHUB_OAUTH_CLIENT_ID=Ivxxxxxxxxxxxx node dist/index.js
```

### Python

```bash
cd python
pip3 install -r requirements.txt --quiet
GITHUB_OAUTH_CLIENT_ID=Ivxxxxxxxxxxxx python3 main.py
```

### Go

```bash
cd go
go run main.go
```

## 驗證

```bash
./verify.sh
```

`verify.sh` 會檢查所有語言的安裝/構建。交互式運行默認會跳過，可以通過設置 `GITHUB_OAUTH_CLIENT_ID` 和 `AUTH_SAMPLE_RUN_INTERACTIVE=1` 來啟用。

要將此範例包含在完整的套件中，請從 `samples/` 根目錄運行 `./verify.sh`。
