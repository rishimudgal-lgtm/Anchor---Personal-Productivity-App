import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FadeSlideTransition extends StatefulWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 20),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curve);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(offset: _slideAnimation.value, child: child),
      ),
      child: widget.child,
    );
  }
}

class BouncingTap extends StatefulWidget {
  const BouncingTap({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
      );
    }
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.color,
    this.gradient,
    this.backgroundColor,
  });

  final double progress; // 0.0 to 1.0
  final double height;
  final Color? color;
  final Gradient? gradient;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final clamped = progress.clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackBg =
        backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * clamped;
          return Stack(
            children: [
              AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: height,
                decoration: BoxDecoration(
                  color: gradient == null
                      ? (color ?? Theme.of(context).colorScheme.primary)
                      : null,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    if (color != null || gradient != null)
                      BoxShadow(
                        color: (color ?? const Color(0xFF0891B2)).withValues(
                          alpha: 0.35,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PulseBeacon extends StatefulWidget {
  const PulseBeacon({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF22D3EE),
  });

  final Widget child;
  final Color glowColor;

  @override
  State<PulseBeacon> createState() => _PulseBeaconState();
}

class _PulseBeaconState extends State<PulseBeacon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glow = Tween<double>(
      begin: 3.0,
      end: 14.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withValues(alpha: 0.38),
              blurRadius: _glow.value,
              spreadRadius: _glow.value / 3,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class CompletionBurst extends StatefulWidget {
  const CompletionBurst({
    super.key,
    required this.child,
    required this.trigger,
  });

  final Widget child;
  final bool trigger;

  @override
  State<CompletionBurst> createState() => _CompletionBurstState();
}

class _CompletionBurstState extends State<CompletionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
  }

  @override
  void didUpdateWidget(covariant CompletionBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion && widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return widget.child;
    }
    return CustomPaint(
      foregroundPainter: _controller.isAnimating
          ? _BurstPainter(animation: _controller)
          : null,
      child: widget.child,
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.animation}) : super(repaint: animation);

  final Animation<double> animation;
  static const particleCount = 10;
  static const colors = [
    Color(0xFF22D3EE),
    Color(0xFF0891B2),
    Color(0xFF22D3EE),
    Color(0xFF818CF8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final progress = animation.value;
    final maxRadius = size.width * 1.1;

    for (var i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi / particleCount) + (math.pi / 10);
      final distance = progress * maxRadius;
      final x = center.dx + math.cos(angle) * distance;
      final y = center.dy + math.sin(angle) * distance;
      final particleSize = (1.0 - progress) * 3.8;

      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => true;
}

// Animated Count-Up Numeric Ticker
class AnimatedCountUp extends StatelessWidget {
  const AnimatedCountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
  });

  final double value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: (MediaQuery.maybeOf(context)?.disableAnimations ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final formatted = decimals == 0
            ? val.toInt().toString()
            : val.toStringAsFixed(decimals);
        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}

// Bouncing Audio/Focus Sound Wave Visualizer Bars
class SoundWaveVisualizer extends StatefulWidget {
  const SoundWaveVisualizer({super.key, required this.isActive});

  final bool isActive;

  @override
  State<SoundWaveVisualizer> createState() => _SoundWaveVisualizerState();
}

class _SoundWaveVisualizerState extends State<SoundWaveVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(covariant SoundWaveVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.isActive && !reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    } else if ((!widget.isActive || reduceMotion) && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 5;
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final phase = (index * 0.22);
              final progress = (_controller.value + phase) % 1.0;
              final reduceMotion =
                  MediaQuery.maybeOf(context)?.disableAnimations ?? false;
              final heightMultiplier = widget.isActive && !reduceMotion
                  ? (math.sin(progress * 2 * math.pi).abs() * 16.0) + 6.0
                  : 4.0;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 3.5,
                height: heightMultiplier,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? const Color(0xFF22D3EE)
                      : const Color(0xFF94A3B8),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF22D3EE,
                            ).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
