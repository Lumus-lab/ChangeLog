import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExplanationScreen(),
    );
  }

  static Future<void> showWelcome(
    BuildContext context, {
    required Future<void> Function() onStart,
    required Future<void> Function() onCompleteAfterHelp,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => FirstLaunchWelcomeSheet(
        onStart: onStart,
        onCompleteAfterHelp: onCompleteAfterHelp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
                    icon: Icons.play_circle_outline,
                    title: '第一次怎麼開始',
                    content: '先寫下一件正在猶豫、需要整理的事，按下「開始一卦」即可完成預設起卦。問題越具體，日後越容易回顧。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.tune,
                    title: '起卦方式差異',
                    content:
                        '預設流程適合先完成一次提問。進階起卦方式可展開使用：數字占適合快速輸入三組直覺正整數，金錢卦保留擲硬幣的儀式感，籌策會模擬分二、掛一、揲四、歸奇，逐步得出六爻。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.account_tree_outlined,
                    title: '如何看本卦、之卦、變爻',
                    content:
                        '本卦是目前情境的主象；之卦在有變爻時出現，象徵事情可能轉向的方向；變爻是這次卦象中特別需要留意的位置。朱熹解卦法則會協助判斷應優先閱讀哪些卦爻辭。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI 啟發觀測模式',
                    content:
                        '您可以透過點擊看廣告來獲取免費的 AI 啟發觀測次數。這不是為了算命給建議，而是透過 AI 解析卦象中的「時位」智慧，引發您的自我覺察。若您注重個人隱私，可以在設定中輸入您的個人 Gemini API Key (BYOK)，應用程式將直接從您的手機連線至 Google。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.history,
                    title: '記錄與回顧',
                    content:
                        '所有起卦與 AI 啟發觀測的紀錄都會儲存在您的手機本地端。您事後可以針對紀錄進行「回顧與驗證」，幫助您練習與精進對《易經》的理解。',
                  ),
                  _buildSection(
                    context,
                    icon: Icons.menu_book,
                    title: '學易與易傳',
                    content:
                        '本應用不僅提供《易經》本文，亦收錄《十翼》（易傳），讓您在起卦之餘也能深入學習《易經》背後的義理。',
                  ),
                  const SizedBox(height: 32),
                  _buildPrivacySection(context),
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

  Widget _buildPrivacySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                '隱私、資料與免責聲明',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '紀錄儲存在本機；AI 啟發觀測可使用標準模式或您自己的 Gemini API Key。本專案僅供民俗學研究與心理輔導參考，不構成醫療、財務或法律建議。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final url = Uri.parse(
                'https://lumus-lab.github.io/ChangeLog/privacy-policy.html',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('查看隱私政策與資料處理說明'),
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

class FirstLaunchWelcomeSheet extends StatelessWidget {
  final Future<void> Function() onStart;
  final Future<void> Function() onCompleteAfterHelp;

  const FirstLaunchWelcomeSheet({
    super.key,
    required this.onStart,
    required this.onCompleteAfterHelp,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.auto_awesome, color: primary, size: 34),
            const SizedBox(height: 16),
            const Text(
              '先問一件正在猶豫的事',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'ChangeLog 會幫你起卦、整理卦象，並留下日後可回顧的紀錄。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '完整使用說明可以隨時在右上角查看。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await onStart();
                if (context.mounted) {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Text('開始'),
            ),
            TextButton(
              onPressed: () async {
                await ExplanationScreen.show(context);
                if (!context.mounted) return;

                final returnToWelcome = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('回到開始畫面？'),
                    content: const Text('要回到歡迎卡，照著真實流程問第一件事嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('直接進入主流程'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text('回到開始'),
                      ),
                    ],
                  ),
                );

                if (returnToWelcome != true) {
                  await onCompleteAfterHelp();
                  if (context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                }
              },
              child: const Text('查看完整說明'),
            ),
          ],
        ),
      ),
    );
  }
}
