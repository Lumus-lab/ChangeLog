import 'package:flutter/material.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExplanationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ChangeLog 使用說明',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    icon: Icons.explore,
                    title: '如何起卦？',
                    content:
                        '1. 數字占：隨心情想出三組「三位數」的數字（例如 168、399、825）。請記得，這三組數字開頭的第一個數字（百位數）不能是 0 哦！\n2. 金錢卦：模擬丟六枚硬幣求取六爻\n3. 籌策：傳統籌策算法，自己輸入獲得的六爻(6,7,8,9)',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI 解卦模式',
                    content:
                        '您可以透過點擊看廣告來獲取免費的 AI 解卦次數。若您注重個人隱私，可以在設定中輸入您的個人 Gemini API Key (BYOK)，應用程式將直接從您的手機連線至 Google，確保您的問題不會經過任何第三方伺服器儲存。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.history,
                    title: '記錄與覆盤',
                    content:
                        '所有起卦與 AI 解卦的紀錄都會儲存在您的手機本地端。您事後可以針對紀錄進行「覆盤與驗證」，幫助您練習與精進對《易經》的理解。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.menu_book,
                    title: '學易與易傳',
                    content:
                        '本應用不僅提供《易經》本文，亦收錄《十翼》（易傳），讓您在起卦之餘也能深入學習《易經》背後的義理。',
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '免責聲明：\n本專案僅供民俗學研究與心理輔導參考，不構成任何醫療、財務或法律建議。如遇身心問題，請諮詢專業人士。',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('我瞭解了'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
