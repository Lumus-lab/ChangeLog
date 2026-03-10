# 隱私權保護與資料處理政策 (Privacy & Data Handling)

《易占：ChangeLog》致力於提供極致的隱私保護。我們體認到占卜與個人問題的私密性，因此在應用程式設計之初，即將「隱私優先 (Privacy-First)」作為核心原則。

## 雙軌制 AI 引擎 (Dual-Track AI Engine)

為了兼顧使用便利性與最高安全需求，本系統實作了**雙軌制 AI 引擎**：

### 1. 專業模式：自帶金鑰 (BRING YOUR OWN KEY - BYOK)
- **運作方式**：使用者在設定中輸入自有的 Google Gemini API Key。
- **隱私層級：最高**。
- **資料流向**：應用程式將直接從您的裝置 (Edge) 連線至 Google 官方 API (`generativelanguage.googleapis.com`)。
- **資料儲存**：您的 API Key 只會存在您裝置的系統級安全環境 (iOS Keychain / Android Keystore) 中，**絕不**會傳送至我們的伺服器或任何第三方。
- **功能優勢**：AI 解卦時不扣除額度且不需觀看獎勵式廣告；部分轉場期間仍可能顯示插頁式廣告。我們無法獲知您的任何提問與解卦內容。
- **廣告 SDK 注意事項**：即使使用 BYOK 模式，應用程式內嵌的廣告 SDK (Google AdMob) 仍可能收集部分裝置與廣告互動資訊，詳見 [Google 隱私政策](https://policies.google.com/privacy)。

### 2. 預設模式：匿名代理 (Cloudflare Worker Proxy)
- **運作方式**：使用者無需自備 API Key，透過觀看獎勵式廣告取得解卦額度。
- **隱私層級：高**。
- **資料流向**：應用程式會將您的提問與卦象傳送至我們部署在 Cloudflare 的邊緣運算節點 (Cloudflare Workers)，再由 Worker 轉發至 Google Gemini API。
- **資料儲存與快取**：
  - Cloudflare Worker 僅作為中繼站，將請求轉發至 Google Gemini API。
  - 為加快回應速度與節省成本，我們使用 Cloudflare KV 快取解卦結果。快取索引以卦象名稱與問題的 SHA-256 雜湊值組成，不包含原始問題文字。
  - **不與身分連結**：所有的請求都是完全匿名的，我們沒有帳號系統，因此您的提問無法被追溯到您個人。

## 本機資料庫 (Local Database)

所有的「起卦紀錄 (Divination Records)」、「問題」與「AI 解卦結果」都只儲存在您手機裡的 **ObjectBox 本機資料庫**中。
除非您主動使用 AI 啟發觀測功能或匯出紀錄，否則這些資料不會離開您的設備。使用預設模式的 AI 功能時，您的提問與卦象將經由 Cloudflare Worker 轉發至 Google Gemini API 處理。

## 第三方 SDK 與資料收集

本應用包含以下第三方 SDK：

| SDK 名稱 | 用途 | 可能收集的資料 |
|---------|------|-------------|
| Google AdMob | 廣告展示 | 裝置識別碼、廣告互動數據、IP 位置 |
| Google Gemini API | AI 解卦（透過 Worker 或 BYOK） | 提問內容、卦象資訊 |
| Cloudflare Workers | API 中繼轉發 | 提問內容（以 hash 形式快取） |

## 資料保留與刪除

- **本機資料**：所有紀錄儲存於您的裝置中。您可隨時透過 app 刪除個別紀錄，或解除安裝 app 以移除所有資料。
- **快取資料**：Cloudflare KV 中的匿名快取資料最長保留 30 天後自動過期刪除。
- **我們不持有您的個人資料**，因此無須額外的帳號刪除流程。

## 聯絡方式

如有任何隱私相關問題，請聯繫：**changelog@lumusxlab.com**

## 總結

不論您選擇哪一種模式，我們都致力於讓您的資料掌握在自己手中。對於具備高度隱私意識的使用者，我們強烈建議使用 **專業模式 (BYOK)**。
