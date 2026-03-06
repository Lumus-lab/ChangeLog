import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/divination_provider.dart';

class DivinationScreen extends ConsumerStatefulWidget {
  const DivinationScreen({super.key});

  @override
  ConsumerState<DivinationScreen> createState() => _DivinationScreenState();
}

class _DivinationScreenState extends ConsumerState<DivinationScreen> {
  int _selectedMethod = 0; // 0: 數字占, 1: 金錢卦, 2: 籌策
  final TextEditingController _questionController = TextEditingController();

  final TextEditingController _num1Ctrl = TextEditingController();
  final TextEditingController _num2Ctrl = TextEditingController();
  final TextEditingController _num3Ctrl = TextEditingController();

  final TextEditingController _yarrowCtrl = TextEditingController();

  bool _isAnimating = false;

  void _startDivination() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請問您想占卜什麼事情？')));
      return;
    }

    final divService = ref.read(divinationServiceProvider);
    List<int>? resultLines;

    if (_selectedMethod == 0) {
      // 數字占
      final n1 = int.tryParse(_num1Ctrl.text);
      final n2 = int.tryParse(_num2Ctrl.text);
      final n3 = int.tryParse(_num3Ctrl.text);
      if (n1 == null ||
          n2 == null ||
          n3 == null ||
          n1 <= 0 ||
          n2 <= 0 ||
          n3 <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('請完整輸入三個正整數')));
        return;
      }
      resultLines = divService.generateNumberDivination(n1, n2, n3);
    } else if (_selectedMethod == 1) {
      // 金錢卦
      resultLines = divService.generateCoinDivination();
    } else {
      // 籌策
      final input = _yarrowCtrl.text.replaceAll(' ', '').replaceAll(',', '');
      if (input.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入剛剛好 6 個數字 (6, 7, 8, 9)')),
        );
        return;
      }
      List<int> lines = [];
      for (int i = 0; i < input.length; i++) {
        final val = int.tryParse(input[i]);
        if (val == null || val < 6 || val > 9) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('籌策輸入只能包含 6, 7, 8, 9')));
          return;
        }
        lines.add(val);
      }
      resultLines = divService.generateYarrowDivination(lines);
    }

    setState(() {
      _isAnimating = true;
    });

    // 模擬易經運算動畫時間
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isAnimating = false;
    });

    if (mounted && resultLines != null) {
      _showResultDialog(resultLines);
    }
  }

  void _showResultDialog(List<int> lines) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            '起卦結果',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '得到的六爻(由下而上)：\n$lines',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              const Text('這組紀錄即將儲存並帶您進入解卦畫面...'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.change_circle_outlined, color: primary),
            const SizedBox(width: 8),
            const Text('太極圖示可放這裡'),
          ],
        ),
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isAnimating ? _buildAnimationView() : _buildMainForm(primary),
        ),
      ),
    );
  }

  Widget _buildMainForm(Color primary) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child:
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primary.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(Icons.cyclone, size: 50, color: primary),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 3000.ms, color: Colors.white24)
                    .rotate(duration: 20.seconds),
          ),
          const SizedBox(height: 48),

          TextField(
            controller: _questionController,
            style: const TextStyle(fontSize: 18),
            maxLength: 50,
            decoration: InputDecoration(
              labelText: '占卜事項 / 動機',
              hintText: '例：這個月的專案能順利上線嗎？',
              labelStyle: TextStyle(color: primary),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primary, width: 2),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),
          Text(
            '選擇起卦方式',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),

          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('數字占')),
              ButtonSegment(value: 1, label: Text('金錢卦')),
              ButtonSegment(value: 2, label: Text('籌策')),
            ],
            selected: {_selectedMethod},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedMethod = newSelection.first;
              });
            },
            style: ButtonStyle(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 12),
              ),
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary.withValues(alpha: 0.2);
                }
                return Colors.transparent;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return primary;
                }
                return Colors.white;
              }),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildMethodInput(),
          ),

          const SizedBox(height: 64),
          ElevatedButton(
                onPressed: _startDivination,
                child: const Text('開始起卦 / Start Divination'),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 2000.ms,
              )
              .shimmer(duration: 4000.ms, color: Colors.white30),
        ],
      ),
    );
  }

  Widget _buildMethodInput() {
    if (_selectedMethod == 0) {
      return Row(
        key: const ValueKey(0),
        children: [
          Expanded(child: _buildNumField(_num1Ctrl, '下卦數')),
          const SizedBox(width: 12),
          Expanded(child: _buildNumField(_num2Ctrl, '上卦數')),
          const SizedBox(width: 12),
          Expanded(child: _buildNumField(_num3Ctrl, '動爻數')),
        ],
      );
    } else if (_selectedMethod == 1) {
      return Card(
        key: const ValueKey(1),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            children: [
              Icon(
                    Icons.monetization_on,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(duration: 2000.ms),
              const SizedBox(height: 16),
              Text(
                '為您隨機模擬連續拋擲三枚銅錢六次\n產生客觀的陰陽變化',
                style: TextStyle(color: Colors.grey[300], height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        key: const ValueKey(2),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.edit_note, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              TextField(
                controller: _yarrowCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 8, fontSize: 20),
                decoration: InputDecoration(
                  labelText: '輸入 6, 7, 8, 9 (由下而上, 共六個)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildNumField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimationView() {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      key: const ValueKey('animating'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.5),
                    width: 4,
                  ),
                ),
                child: Icon(Icons.cyclone, size: 100, color: primary)
                    .animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 1.seconds)
                    .shimmer(duration: 1000.ms, color: Colors.white54),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2.seconds,
              ),
          const SizedBox(height: 48),
          Text(
                '易有太極，是生兩儀\n兩儀生四象，四象生八卦...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: primary,
                  letterSpacing: 2,
                  height: 1.8,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds, delay: 1.seconds),
        ],
      ),
    );
  }
}
