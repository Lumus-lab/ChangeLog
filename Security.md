# 系統安全性架構 (Security Architecture)

《易經排盤與解卦》App 的安全性建立在「前端零信任」與「後端無狀態」的架構之上。

## 1. API Key 安全管理 (API Key Security)

### 用戶端 (BYOK 模式)
- 使用 `flutter_secure_storage` 套件。
- 在 iOS 上，API Key 被加密並儲存於 **Keychain**。
- 在 Android 上，API Key 被加密並儲存於 **Keystore**。
- 即使裝置被 Root 或 Jailbreak，要輕易提取金鑰依舊具備一定難度。
- App 移除時，該金鑰資料通常會隨之被系統銷毀（依 OS 原生行為而定）。

### 伺服器端 (Cloudflare Worker 模式)
- 開發者的官方 Gemini API Key **絕對不會**被打包在 Flutter App 的程式碼中。
- 金鑰被安全地保存在 Cloudflare Secrets 內。
- Worker 程式碼在執行時，動態將 Secret 注入環境變數 (`env.GEMINI_API_KEY`)。
- 這樣完全杜絕了被惡意反編譯 App 盜取金鑰的風險。

## 2. 網路安全 (Network Security)

### HTTPS / TLS 傳輸
所有的資料傳輸—無論是直接連線 Google API (BYOK 模式) 還是連線 Cloudflare Worker—都強制使用 TLS 1.2+ 加密通道，防止中間人攻擊 (MITM)。

### Cloudflare Worker 防護
- **App ID 驗證**：Worker 會檢查 Request Header 的 `app-id`，阻擋部分非預期的外部直接呼叫（雖然這不是強綁定，但能防護簡易爬蟲）。
- **CORS 限制**：嚴格限制只接受來自特定來源與方式 (POST) 的請求。
- **速率限制 (Rate Limiting)**：透過 Cloudflare WAF 原生防護，避免遭到 DDoS 或被惡意消耗 API 額度。

## 3. 資料庫安全 (Database Security)

- 應用程式使用 `ObjectBox` 作為本機資料庫。
- 資料庫檔案儲存於 App Sandbox （沙盒）的專屬資料夾中，在非 Root 設備上，其他應用程式無法存取。
