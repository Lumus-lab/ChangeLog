# 隱私權保護與資料處理政策 (Privacy & Data Handling)

《易經排盤與解卦》致力於提供極致的隱私保護。我們體認到占卜與個人問題的私密性，因此在應用程式設計之初，即將「隱私優先 (Privacy-First)」作為核心原則。

## 雙軌制 AI 引擎 (Dual-Track AI Engine)

為了兼顧使用便利性與最高安全需求，本系統實作了**雙軌制 AI 引擎**：

### 1. 專業模式：自帶金鑰 (BRING YOUR OWN KEY - BYOK)
- **運作方式**：使用者在設定中輸入自有的 Google Gemini API Key。
- **隱私層級：最高**。
- **資料流向**：應用程式將直接從您的裝置 (Edge) 連線至 Google 官方 API (`generativelanguage.googleapis.com`)。
- **資料儲存**：您的 API Key 只會存在您裝置的系統級安全環境 (iOS Keychain / Android Keystore) 中，**絕不**會傳送至我們的伺服器或任何第三方。
- **功能優勢**：永久免除所有廣告，並且我們無法獲知您的任何提問與解卦內容。

### 2. 預設模式：匿名代理 (Cloudflare Worker Proxy)
- **運作方式**：使用者無需自備 API Key，透過觀看獎勵式廣告取得解卦額度。
- **隱私層級：高**。
- **資料流向**：應用程式會將您的提問與卦象傳送至我們部署在 Cloudflare 的邊緣運算節點 (Cloudflare Workers)。
- **資料儲存與快取**：
  - Cloudflare Worker 僅作為中繼站，將請求轉發至 Google Gemini API。
  - 為加快回應速度與節省成本，我們可能會使用 Cloudflare KV 快取匿名的解卦結果（包含卦名與提問關鍵字）。
  - **不與身分連結**：所有的請求都是完全匿名的，我們沒有帳號系統，因此您的提問無法被追溯到您個人。

## 本機資料庫 (Local Database)

所有的「起卦紀錄 (Divination Records)」、「問題」與「AI 解卦結果」都只儲存在您手機裡的 **ObjectBox 本機資料庫**中。
除非您主動分享或匯出，否則這些資料永遠不會離開您的設備。

## 總結

不論您選擇哪一種模式，我們都致力於讓您的資料掌握在自己手中。對於具備高度隱私意識的使用者，我們強烈建議使用 **專業模式 (BYOK)**。
