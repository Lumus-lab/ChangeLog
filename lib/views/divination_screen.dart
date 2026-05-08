import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import '../models/yarrow_simulation.dart';
import '../providers/divination_provider.dart';
import '../services/storage_service.dart';
import 'divination_result_screen.dart';
import 'explanation_screen.dart';
import 'settings_screen.dart';
import 'widgets/yarrow_ritual_animation.dart';

class DivinationScreen extends ConsumerStatefulWidget {
  final bool enableAnimations;

  const DivinationScreen({super.key, this.enableAnimations = true});

  @override
  ConsumerState<DivinationScreen> createState() => _DivinationScreenState();
}

class _DivinationScreenState extends ConsumerState<DivinationScreen> {
  static const Duration _yarrowLineRevealDelay = Duration(seconds: 8);

  int _selectedMethod = 0; // 0: 數字占, 1: 金錢卦, 2: 籌策
  bool _advancedMethodsExpanded = false;
  final TextEditingController _questionController = TextEditingController();

  final TextEditingController _num1Ctrl = TextEditingController();
  final TextEditingController _num2Ctrl = TextEditingController();
  final TextEditingController _num3Ctrl = TextEditingController();

  bool _isAnimating = false;
  bool _isCoinRolling = false;
  final List<int> _coinLines = [];
  bool _saveYarrowProcessDetail = true;
  YarrowSimulationResult? _activeYarrowSimulation;
  int _visibleYarrowLineCount = 0;
  bool _isYarrowAnimating = false;
  bool _hasShownYarrowResult = false;
  Timer? _yarrowAnimationTimer;

  void _resetCoinState() {
    setState(() {
      _isCoinRolling = false;
      _coinLines.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    try {
      _saveYarrowProcessDetail = ref
          .read(storageServiceProvider)
          .saveYarrowProcessDetail;
    } on ProviderException catch (error) {
      if (error.exception is! UnimplementedError) rethrow;
    }
  }

  @override
  void dispose() {
    _yarrowAnimationTimer?.cancel();
    _questionController.dispose();
    _num1Ctrl.dispose();
    _num2Ctrl.dispose();
    _num3Ctrl.dispose();
    super.dispose();
  }

  void _resetYarrowState() {
    _yarrowAnimationTimer?.cancel();
    _yarrowAnimationTimer = null;
    _activeYarrowSimulation = null;
    _visibleYarrowLineCount = 0;
    _isYarrowAnimating = false;
    _hasShownYarrowResult = false;
  }

  void _resetForm() {
    setState(() {
      _questionController.clear();
      _num1Ctrl.clear();
      _num2Ctrl.clear();
      _num3Ctrl.clear();
      _selectedMethod = 0;
      _advancedMethodsExpanded = false;
      _isCoinRolling = false;
      _coinLines.clear();
      _resetYarrowState();
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

    if (_advancedMethodsExpanded && _selectedMethod == 1) {
      _handleCoinDivinationStep(question);
      return;
    }

    final divService = ref.read(divinationServiceProvider);
    List<int> resultLines;
    String methodName = "直覺起卦";

    if (!_advancedMethodsExpanded) {
      resultLines = divService.generateIntuitiveDivination();
    } else if (_selectedMethod == 0) {
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
      methodName = "數字占";
    } else {
      await _handleYarrowSimulation(question);
      return;
    }

    setState(() {
      _isAnimating = true;
    });

    // 模擬易經運算動畫時間
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _isAnimating = false;
    });

    if (mounted) {
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

  Future<void> _handleYarrowSimulation(String question) async {
    final divService = ref.read(divinationServiceProvider);
    final simulation = divService.generateYarrowSimulation();
    _yarrowAnimationTimer?.cancel();

    setState(() {
      _activeYarrowSimulation = simulation;
      _visibleYarrowLineCount = 0;
      _isYarrowAnimating = true;
      _hasShownYarrowResult = false;
    });

    _yarrowAnimationTimer = Timer.periodic(_yarrowLineRevealDelay, (_) {
      if (!mounted || !_isYarrowAnimating) {
        _yarrowAnimationTimer?.cancel();
        _yarrowAnimationTimer = null;
        return;
      }

      final nextCount = _visibleYarrowLineCount + 1;
      setState(() => _visibleYarrowLineCount = nextCount);

      if (nextCount >= simulation.lines.length) {
        _completeYarrowSimulation(question);
      }
    });
  }

  void _completeYarrowSimulation(String question) {
    final simulation = _activeYarrowSimulation;
    if (!mounted ||
        _hasShownYarrowResult ||
        simulation == null ||
        question.isEmpty) {
      return;
    }

    _yarrowAnimationTimer?.cancel();
    _yarrowAnimationTimer = null;

    final methodDetailJson = _saveYarrowProcessDetail
        ? jsonEncode(simulation.detail.toJson())
        : null;

    setState(() {
      _hasShownYarrowResult = true;
      _visibleYarrowLineCount = simulation.lines.length;
      _isYarrowAnimating = false;
    });

    _showResultDialog(
      simulation.lines,
      question,
      '籌策',
      methodDetailJson: methodDetailJson,
    );
  }

  void _skipYarrowAnimation() {
    final question = _questionController.text.trim();
    _completeYarrowSimulation(question);
  }

  void _showResultDialog(
    List<int> lines,
    String question,
    String method, {
    String? methodDetailJson,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DivinationResultScreen(
          lines: lines,
          question: question,
          method: method,
          methodDetailJson: methodDetailJson,
        ),
      ),
    );
    if (mounted) {
      _resetForm();
    }
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
          child: _isYarrowAnimating
              ? _buildYarrowAnimationView()
              : _isAnimating
              ? _buildAnimationView()
              : _buildMainForm(primary),
        ),
      ),
    );
  }

  Widget _buildMainForm(Color primary) {
    return Stack(
      key: const ValueKey('form'),
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              key: const ValueKey('divination-background-logo-align'),
              alignment: Alignment.center,
              child: _maybeRepeatRotate(
                Opacity(
                  opacity: 0.08,
                  child: SizedBox(
                    key: const ValueKey('divination-background-logo'),
                    width: 520,
                    height: 520,
                    child: SvgPicture.asset('assets/images/app_icon.svg'),
                  ),
                ),
                duration: 60.seconds,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '先問一件正在猶豫的事',
                style: GoogleFonts.notoSansTc(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ).animateIfEnabled(
                widget.enableAnimations,
                (child) => child
                    .animate()
                    .fadeIn(delay: 120.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(height: 8),
              Text(
                '寫下問題，讓 ChangeLog 帶你完成一次起卦、整理卦象，並留下日後可回顧的紀錄。',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 15,
                  height: 1.6,
                ),
              ).animateIfEnabled(
                widget.enableAnimations,
                (child) => child.animate().fadeIn(delay: 180.ms),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _questionController,
                style: const TextStyle(fontSize: 18),
                maxLength: 80,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '想問的事',
                  hintText: '例：我該不該接受這個合作邀請？',
                  helperText: '問題越具體，日後越容易回顧。',
                  helperMaxLines: 2,
                  labelStyle: TextStyle(color: primary),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ).animateIfEnabled(
                widget.enableAnimations,
                (child) => child
                    .animate()
                    .fadeIn(delay: 220.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
              const SizedBox(height: 12),
              _buildActionButton(),
              const SizedBox(height: 18),
              _buildAdvancedMethods(primary),
              const SizedBox(height: 12),
              _buildRulesSummary(primary),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedMethods(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        initiallyExpanded: _advancedMethodsExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _advancedMethodsExpanded = expanded;
            if (!expanded) {
              _isCoinRolling = false;
              _coinLines.clear();
            }
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(Icons.tune, color: primary),
        title: const Text(
          '進階起卦方式',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('不確定怎麼選時，可以先使用預設方式。'),
        children: [
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
                _isCoinRolling = false;
                _coinLines.clear();
                _resetYarrowState();
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
          ),
          const SizedBox(height: 12),
          _buildMethodHint(),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildMethodInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesSummary(Color primary) {
    return Container(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(Icons.info_outline, color: primary, size: 20),
        title: Text(
          '輕量須知',
          style: TextStyle(
            color: Colors.grey[200],
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('心中有疑，誠意提問；同一件事不反覆連占。'),
        children: [
          _buildRuleItem('不誠不占：', '心意不誠者不占'),
          _buildRuleItem('不義不占：', '不義之事、違法之事不占'),
          _buildRuleItem('不疑不占：', '無所疑惑、僅供戲玩不占'),
          const Divider(height: 24),
          _buildRuleItem('易經誡示：', '「初筮告，再三瀆，瀆則不告」— 同一事不可連占。'),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_advancedMethodsExpanded && _selectedMethod == 1) {
      String btnText = _isCoinRolling ? '停止' : '擲第 ${_coinLines.length + 1} 爻';
      final button = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCoinRolling
              ? Colors.redAccent
              : Theme.of(context).colorScheme.primary,
        ),
        onPressed: _startDivination,
        child: Text(btnText),
      );

      if (!widget.enableAnimations) return button;

      return button
          .animate(target: _isCoinRolling ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 300.ms,
          );
    }

    final button = ElevatedButton(
      onPressed: _startDivination,
      child: const Text('開始一卦'),
    );

    if (!widget.enableAnimations) return button;

    return button
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.02, 1.02),
          duration: 2000.ms,
        )
        .shimmer(duration: 4000.ms, color: Colors.white30);
  }

  Widget _maybeRepeatRotate(Widget child, {required Duration duration}) {
    if (!widget.enableAnimations) return child;
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: duration);
  }

  Widget _buildMethodInput() {
    if (_selectedMethod == 0) {
      return Row(
        key: const ValueKey(0),
        children: [
          Expanded(child: _buildNumField(_num1Ctrl, '第一數', '下卦數')),
          const SizedBox(width: 12),
          Expanded(child: _buildNumField(_num2Ctrl, '第二數', '上卦數')),
          const SizedBox(width: 12),
          Expanded(child: _buildNumField(_num3Ctrl, '第三數', '動爻數')),
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
              const SizedBox(height: 8),
              Text(
                '已完成 ${_coinLines.length}/6 爻',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.grass,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '模擬四營十八變，逐步得出六爻。',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('保存完整過程'),
                subtitle: const Text('關閉時僅保存卦象結果。'),
                value: _saveYarrowProcessDetail,
                onChanged: (value) async {
                  setState(() => _saveYarrowProcessDetail = value);
                  await ref
                      .read(storageServiceProvider)
                      .setSaveYarrowProcessDetail(value);
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMethodHint() {
    final text = switch (_selectedMethod) {
      0 => '數字占：適合快速起卦，輸入三組直覺想到的正整數。',
      1 => '金錢卦：模擬擲硬幣六次，保留儀式感。',
      _ => '籌策：模擬傳統分二、掛一、揲四、歸奇的起卦過程。',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumField(
    TextEditingController ctrl,
    String label,
    String helper,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

  Widget _buildYarrowAnimationView() {
    final simulation = _activeYarrowSimulation;
    final primary = Theme.of(context).colorScheme.primary;
    final visibleLines = simulation == null
        ? <int>[]
        : simulation.lines.take(_visibleYarrowLineCount).toList();
    final nextLine = (_visibleYarrowLineCount + 1).clamp(1, 6);
    final progress = _visibleYarrowLineCount / 6;

    return SingleChildScrollView(
      key: const ValueKey('yarrow-animating'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '籌策推演中',
            style: GoogleFonts.notoSansTc(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '分二 · 掛一 · 揲四 · 歸奇',
            style: TextStyle(color: Colors.grey[300], fontSize: 16),
          ),
          const SizedBox(height: 10),
          Text(
            _visibleYarrowLineCount >= 6
                ? '六爻已成，整理卦象中...'
                : '第 $nextLine 爻正在成形，完整推演約 48 秒',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (simulation != null)
            YarrowRitualAnimation(
              simulation: simulation,
              visibleLineCount: _visibleYarrowLineCount,
              enableAnimations: widget.enableAnimations,
            ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Theme.of(context).colorScheme.surface,
            color: primary,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            '已成 $_visibleYarrowLineCount / 6 爻',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: List.generate(6, (index) {
              final hasValue = index < visibleLines.length;
              return Chip(
                label: Text(hasValue ? '${visibleLines[index]}' : '·'),
                backgroundColor: hasValue
                    ? primary.withValues(alpha: 0.18)
                    : Theme.of(context).colorScheme.surface,
              );
            }),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _skipYarrowAnimation,
            icon: const Icon(Icons.skip_next),
            label: const Text('略過動畫'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.5),
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: content),
          ],
        ),
      ),
    );
  }
}

extension _ConditionalAnimation on Widget {
  Widget animateIfEnabled(
    bool enabled,
    Widget Function(Widget child) animationBuilder,
  ) {
    if (!enabled) return this;
    return animationBuilder(this);
  }
}
