import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isSaving = false;
  int _credits = 0;
  bool _hasByok = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = ref.read(storageServiceProvider);
    final key = await storage.getByokApiKey();
    setState(() {
      _apiKeyController.text = key ?? '';
      _hasByok = key != null && key.isNotEmpty;
      _credits = storage.adCredits;
    });
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    final storage = ref.read(storageServiceProvider);
    setState(() => _isSaving = true);

    if (key.isEmpty) {
      await storage.deleteByokApiKey();
    } else {
      await storage.setByokApiKey(key);
    }

    setState(() {
      _isSaving = false;
      _hasByok = key.isNotEmpty;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(key.isEmpty ? '已清除 API Key' : 'API Key 儲存成功！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('設定與隱私')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AD CREDITS SECTION
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.stars, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('免廣告 AI 解卦額度', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      '$_credits 次',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    if (!_hasByok) ...[
                      const SizedBox(height: 16),
                      Text(
                        '您可以透過觀看廣告來增加解卦次數。每個廣告將提供 3 次免費解卦機會。使用 BYOK 專業模式則不扣除額度。',
                        style: TextStyle(
                          color: Colors.grey[400],
                          height: 1.5,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // BYOK SECTION
            Text(
              '專業模式 (BYOK)',
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '輸入您專屬的 Google Gemini API Key。使用自己的 Key 將完全保障您的隱私，且永久免除廣告干擾。您的 Key 將被加密儲存在設備中，絕不上傳。',
              style: TextStyle(color: Colors.grey[400], height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _apiKeyController.clear(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveApiKey,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('安全儲存 API Key'),
            ),
          ],
        ),
      ),
    );
  }
}
