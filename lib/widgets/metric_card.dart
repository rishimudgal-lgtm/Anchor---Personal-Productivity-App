import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'animations.dart';
import 'feature_artwork.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.gradient,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final Gradient? gradient;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? AppTheme.primaryLight;

    final content = GlassCard(
      borderRadius: BorderRadius.circular(22),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FeatureArtwork(
                icon: icon,
                color: iconColor,
                size: 40,
                gradient: gradient,
              ),
              if (subtitle != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.cardDarkElevated
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.borderGlassDark
                          : AppTheme.borderGlassLight,
                    ),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.inkMutedDark : AppTheme.inkMutedLight,
            ),
          ),
        ],
      ),
    );

    final card = BouncingTap(onTap: onTap, child: content);
    if (onTap == null) return card;
    return Semantics(
      button: true,
      label: '$label, $value',
      onTapHint: 'Open the related $label view',
      child: Tooltip(message: 'Open $label', child: card),
    );
  }
}
