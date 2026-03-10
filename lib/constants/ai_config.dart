class AIConfig {
  /// 統一的 Gemini 模型名稱（BYOK 與 Worker 共用）
  static const String geminiModel = 'gemini-2.5-flash-lite';

  /// 每日免費 AI 解卦次數基底
  static const int dailyFreeCredits = 3;

  /// 觀看廣告獲得的解卦次數
  static const int adRewardCredits = 3;
}
