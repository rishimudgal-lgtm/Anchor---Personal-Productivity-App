import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import 'animations.dart';

class InteractiveTimerWidget extends StatefulWidget {
  const InteractiveTimerWidget({
    super.key,
    required this.state,
    this.compact = false,
  });

  final HubState state;
  final bool compact;

  @override
  State<InteractiveTimerWidget> createState() => _InteractiveTimerWidgetState();
}

class _InteractiveTimerWidgetState extends State<InteractiveTimerWidget>
    with SingleTickerProviderStateMixin {
  int _totalSeconds = 25 * 60; // 25 min default
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  DateTime? _endAt;
  bool _completionInProgress = false;
  String _sessionLabel = 'Deep Focus';
  late final AnimationController _pulseController;

  static const List<Map<String, Object>> _presets = [
    {'name': '25m Focus', 'minutes': 25, 'label': 'Pomodoro'},
    {'name': '15m Sprint', 'minutes': 15, 'label': 'Sprint'},
    {'name': '50m Deep', 'minutes': 50, 'label': 'Deep Work'},
    {'name': '5m Rest', 'minutes': 5, 'label': 'Break'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _restoreTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations &&
        !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (MediaQuery.of(context).disableAnimations &&
        _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  Future<void> _restoreTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(HubState.timerStateKey);
      if (raw == null) return;
      final saved = jsonDecode(raw) as Map<String, Object?>;
      final total = saved['totalSeconds'] as int?;
      final remaining = saved['remainingSeconds'] as int?;
      final running = saved['isRunning'] as bool? ?? false;
      final label = saved['label'] as String? ?? 'Deep Focus';
      final parsedEnd = saved['endAt'] is String
          ? DateTime.tryParse(saved['endAt']! as String)
          : null;
      if (total == null || total < 60 || total > 7200 || remaining == null) {
        await prefs.remove(HubState.timerStateKey);
        return;
      }

      var restoredRemaining = remaining.clamp(0, total);
      if (running && parsedEnd != null) {
        final millisecondsLeft = parsedEnd
            .difference(DateTime.now())
            .inMilliseconds;
        restoredRemaining = millisecondsLeft <= 0
            ? 0
            : ((millisecondsLeft + 999) ~/ 1000).clamp(0, total);
      }
      if (!mounted) return;
      setState(() {
        _totalSeconds = total;
        _remainingSeconds = restoredRemaining;
        _sessionLabel = label;
        _isRunning = running && parsedEnd != null && restoredRemaining > 0;
        _endAt = _isRunning ? parsedEnd : null;
      });
      if (_isRunning) {
        _startTicker();
      } else if (running && restoredRemaining == 0) {
        await _onTimerComplete();
      }
    } catch (_) {
      // The timer can still be used if its stored session is corrupt.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startTimer() async {
    if (_remainingSeconds <= 0) return;
    _endAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
    setState(() => _isRunning = true);
    HapticFeedback.mediumImpact();
    await _persistTimer();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final endAt = _endAt;
      if (endAt == null) return;
      final millisecondsLeft = endAt.difference(DateTime.now()).inMilliseconds;
      final remaining = millisecondsLeft <= 0
          ? 0
          : (millisecondsLeft + 999) ~/ 1000;
      if (mounted) setState(() => _remainingSeconds = remaining);
      if (remaining == 0) _onTimerComplete();
    });
  }

  Future<void> _pauseTimer() async {
    final endAt = _endAt;
    if (endAt != null) {
      final millisecondsLeft = endAt.difference(DateTime.now()).inMilliseconds;
      _remainingSeconds = millisecondsLeft <= 0
          ? 0
          : (millisecondsLeft + 999) ~/ 1000;
    }
    _timer?.cancel();
    _endAt = null;
    setState(() => _isRunning = false);
    HapticFeedback.lightImpact();
    await _persistTimer();
    if (_remainingSeconds == 0) await _onTimerComplete();
  }

  Future<void> _resetTimer([int? newMinutes]) async {
    _timer?.cancel();
    _endAt = null;
    _completionInProgress = false;
    final minutes = newMinutes ?? (_totalSeconds ~/ 60);
    setState(() {
      _totalSeconds = math.max(1, minutes) * 60;
      _remainingSeconds = _totalSeconds;
      _isRunning = false;
    });
    HapticFeedback.selectionClick();
    await _persistTimer();
  }

  Future<void> _persistTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        HubState.timerStateKey,
        jsonEncode({
          'totalSeconds': _totalSeconds,
          'remainingSeconds': _remainingSeconds,
          'isRunning': _isRunning,
          'endAt': _endAt?.toIso8601String(),
          'label': _sessionLabel,
        }),
      );
    } catch (_) {
      // Keep the timer usable if local storage is unavailable.
    }
  }

  void _adjustTime(int deltaMinutes) {
    if (_isRunning) return;
    final currentMins = _totalSeconds ~/ 60;
    final newMins = (currentMins + deltaMinutes).clamp(1, 120);
    _resetTimer(newMins);
  }

  Future<void> _onTimerComplete() async {
    if (_completionInProgress) return;
    _completionInProgress = true;
    _timer?.cancel();
    _endAt = null;
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
    await _persistTimer();
    HapticFeedback.vibrate();

    final minutesDone = math.max(1, _totalSeconds ~/ 60);
    await widget.state.addFocusSession(minutesDone, label: _sessionLabel);

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: AppTheme.amber, size: 28),
              SizedBox(width: 8),
              Text('Focus Session Complete'),
            ],
          ),
          content: Text(
            'Session finished: $minutesDone minutes of $_sessionLabel logged to your weekly productivity record.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetTimer();
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _finishEarly() async {
    final endAt = _endAt;
    if (endAt != null) {
      final millisecondsLeft = endAt.difference(DateTime.now()).inMilliseconds;
      _remainingSeconds = millisecondsLeft <= 0
          ? 0
          : (millisecondsLeft + 999) ~/ 1000;
    }
    _timer?.cancel();
    _endAt = null;
    setState(() => _isRunning = false);
    final elapsedSec = _totalSeconds - _remainingSeconds;
    final elapsedMin = (elapsedSec / 60).round();
    if (elapsedMin >= 1) {
      await widget.state.addFocusSession(elapsedMin, label: _sessionLabel);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged $elapsedMin minutes of $_sessionLabel!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    await _resetTimer();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _totalSeconds > 0
        ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    final timerSize = widget.compact ? 180.0 : 220.0;

    return GlassCard(
      elevated: true,
      glow: _isRunning,
      glowColor: AppTheme.primaryLight,
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Studio Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.skyGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isRunning
                        ? const PulseBeacon(
                            child: Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : const Icon(
                            Icons.timer_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sessionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          SoundWaveVisualizer(isActive: _isRunning),
                          const SizedBox(width: 6),
                          Text(
                            _isRunning
                                ? 'Live session in progress'
                                : 'Ready to start',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isRunning
                                  ? AppTheme.primaryLight
                                  : (isDark
                                        ? AppTheme.inkMutedDark
                                        : AppTheme.inkMutedLight),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                tooltip: 'Edit Topic',
                onPressed: () => _showLabelPicker(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // High-Tech Circular Focus Dial
          SizedBox(
            width: timerSize,
            height: timerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer breathing aura when active
                if (_isRunning)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) => Container(
                      width: timerSize - 10 + (_pulseController.value * 14),
                      height: timerSize - 10 + (_pulseController.value * 14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryLight.withValues(
                              alpha: 0.25 * _pulseController.value,
                            ),
                            blurRadius: 26,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                CustomPaint(
                  size: Size(timerSize, timerSize),
                  painter: _StudioTimerPainter(
                    progress: progress,
                    isDark: isDark,
                    activeColor: _isRunning
                        ? AppTheme.primaryLight
                        : AppTheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: widget.compact ? 36 : 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(_totalSeconds ~/ 60)} MIN INTERVAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppTheme.inkMutedDark
                            : AppTheme.inkMutedLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Quick +/- 5m time adjustment buttons
          if (!_isRunning)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Decrease 5 min',
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  onPressed: () => _adjustTime(-5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Adjust duration',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.inkMutedDark
                        : AppTheme.inkMutedLight,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Add 5 min',
                  icon: const Icon(Icons.add_rounded, size: 16),
                  onPressed: () => _adjustTime(5),
                ),
              ],
            ),
          const SizedBox(height: 12),

          // Preset Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _presets.map((preset) {
                final mins = preset['minutes'] as int;
                final isSelected = (_totalSeconds ~/ 60) == mins;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(preset['name'] as String),
                    selected: isSelected,
                    onSelected: _isRunning
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(
                                () => _sessionLabel = preset['label'] as String,
                              );
                              _resetTimer(mins);
                            }
                          },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),

          // Executive Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reset Timer',
                onPressed: () => _resetTimer(),
              ),
              const SizedBox(width: 14),
              BouncingTap(
                onTap: _isRunning ? _pauseTimer : _startTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.skyGradient,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? 'Pause' : 'Start Focus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                icon: const Icon(Icons.check_circle_outline_rounded),
                tooltip: 'Finish & Record',
                onPressed: _remainingSeconds < _totalSeconds
                    ? _finishEarly
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLabelPicker(BuildContext context) {
    final controller = TextEditingController(text: _sessionLabel);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Topic'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Linear Algebra, Code Review, Strategy',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _sessionLabel = controller.text.trim());
                _persistTimer();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _StudioTimerPainter extends CustomPainter {
  _StudioTimerPainter({
    required this.progress,
    required this.isDark,
    required this.activeColor,
  });

  final double progress;
  final bool isDark;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 20) / 2;
    const strokeWidth = 11.0;

    // Outer subtle hairline
    final outerHairline = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius + 8, outerHairline);

    // Track paint
    final trackPaint = Paint()
      ..color = isDark ? AppTheme.cardDarkElevated : const Color(0xFFE2EBF5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Sweeping Gradient Arc
    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [activeColor, AppTheme.electricCyan, activeColor],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glowing tip indicator
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipX = center.dx + math.cos(tipAngle) * radius;
    final tipY = center.dy + math.sin(tipAngle) * radius;

    final tipGlow = Paint()
      ..color = AppTheme.electricCyan.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(tipX, tipY), 6, tipGlow);

    final tipDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(tipX, tipY), 3.5, tipDot);
  }

  @override
  bool shouldRepaint(covariant _StudioTimerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isDark != isDark ||
      oldDelegate.activeColor != activeColor;
}
