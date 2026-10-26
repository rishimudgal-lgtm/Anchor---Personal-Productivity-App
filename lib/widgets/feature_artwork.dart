import 'package:flutter/material.dart';

/// A compact vector illustration badge made from Flutter shapes and Material
/// icons. It keeps category art crisp at every display density.
class FeatureArtwork extends StatelessWidget {
  const FeatureArtwork({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.gradient,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = gradient == null ? color : Colors.white;
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.3),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient:
                gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: dark ? 0.24 : 0.16),
                    color.withValues(alpha: dark ? 0.10 : 0.07),
                  ],
                ),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: size * 0.13,
                right: size * 0.13,
                child: Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: size * 0.14,
                bottom: size * 0.15,
                child: Container(
                  width: size * 0.21,
                  height: size * 0.055,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              Center(
                child: Icon(icon, color: foreground, size: size * 0.48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
