import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/divination_provider.dart';
import 'divination_result_screen.dart';
import 'explanation_screen.dart';
import 'settings_screen.dart';

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
  bool _isCoinRolling = false;
  final List<int> _coinLines = [];

  void _resetCoinState() {
    setState(() {
      _isCoinRolling = false;
      _coinLines.clear();
    });
  }

  void _startDivination() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請問您想占卜什麼事情？')));
      return;
    }

    if (_selectedMethod == 1) {
      _handleCoinDivinationStep(question);
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
      String methodName = _selectedMethod == 0 ? "數字占" : "籌策";
      _showResultDialog(resultLines, question, methodName);
    }
  }

  void _handleCoinDivinationStep(String question) async {
    if (_isCoinRolling) {
      // Stop rolling, generate a line
      final divService = ref.read(divinationServiceProvider);
      final line = divService.generateSingleCoin();
      setState(() {
        _isCoinRolling = false;
        _coinLines.add(line);
      });

      if (_coinLines.length >= 6) {
        // Show result
        setState(() {
          _isAnimating = true;
        });

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _isAnimating = false;
        });

        final linesCopy = List<int>.from(_coinLines);
        _resetCoinState();

        if (mounted) {
          _showResultDialog(linesCopy, question, "金錢卦");
        }
      }
    } else {
      // Start rolling
      setState(() {
        _isCoinRolling = true;
      });
    }
  }

  void _showResultDialog(List<int> lines, String question, String method) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DivinationResultScreen(
          lines: lines,
          question: question,
          method: method,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/app_icon.svg',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text('易占'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '設定',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => ExplanationScreen.show(context),
            tooltip: '使用說明',
          ),
        ],
        // toolbarHeight: 0,
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
                SizedBox(
                      width: 240,
                      height: 240,
                      child: SvgPicture.asset('assets/images/app_icon.svg'),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 4000.ms, color: Colors.white24)
                    .rotate(duration: 40.seconds),
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
                _resetCoinState();
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
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_selectedMethod == 1) {
      String btnText = _isCoinRolling
          ? '停止'
          : '開始骰 (${_coinLines.length + 1}/6)';
      return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCoinRolling
                  ? Colors.redAccent
                  : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _startDivination,
            child: Text(btnText),
          )
          .animate(target: _isCoinRolling ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 300.ms,
          );
    }

    return ElevatedButton(
          onPressed: _startDivination,
          child: const Text('開始起卦 / Start Divination'),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 2000.ms,
        )
        .shimmer(duration: 4000.ms, color: Colors.white30);
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
                    color: _isCoinRolling
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                  )
                  .animate(target: _isCoinRolling ? 1 : 0)
                  .rotate(duration: 300.ms)
                  .shimmer(duration: 1000.ms),
              const SizedBox(height: 16),
              Text(
                '點擊下方按鈕骰六次以起卦',
                style: TextStyle(
                  color: Colors.grey[300],
                  height: 1.5,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (_coinLines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _coinLines
                        .map(
                          (l) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              child: Text(
                                l.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
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
          SizedBox(
                width: 180,
                height: 180,
                child: SvgPicture.asset('assets/images/app_icon.svg'),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 10.seconds)
              .shimmer(duration: 1000.ms, color: Colors.white54),
          const SizedBox(height: 48),
          Text(
                '易有太極，是生兩儀\n兩儀生四象，四象生八卦...',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTc(
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
