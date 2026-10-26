import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'animations.dart';
import 'feature_artwork.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.artworkColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? artworkColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FeatureArtwork(
              icon: icon,
              color: artworkColor ?? AppTheme.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppTheme.inkMutedDark : AppTheme.inkMutedLight,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              BouncingTap(
                onTap: onAction,
                child: FilledButton.tonal(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
