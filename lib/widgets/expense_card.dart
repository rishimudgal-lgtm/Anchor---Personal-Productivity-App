import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../models.dart';
import 'animations.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.entry,
    required this.currency,
    this.onTap,
    this.onDelete,
  });

  final ExpenseEntry entry;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  static Map<String, Object> categoryDetails(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return {
          'icon': Icons.restaurant_rounded,
          'color': AppTheme.coral,
          'bg': isDark ? const Color(0xFF3B1D11) : AppTheme.coralSoft,
        };
      case 'transport':
        return {
          'icon': Icons.directions_bus_rounded,
          'color': AppTheme.primary,
          'bg': isDark ? const Color(0xFF0C2B42) : const Color(0xFFE0F2FE),
        };
      case 'study':
      case 'education':
        return {
          'icon': Icons.school_rounded,
          'color': AppTheme.violet,
          'bg': isDark ? const Color(0xFF2E174D) : AppTheme.violetSoft,
        };
      case 'home':
      case 'groceries':
        return {
          'icon': Icons.local_grocery_store_rounded,
          'color': AppTheme.primary,
          'bg': isDark ? AppTheme.cardDarkElevated : AppTheme.iceBlueSoft,
        };
      case 'entertainment':
        return {
          'icon': Icons.movie_outlined,
          'color': const Color(0xFFEC4899),
          'bg': isDark ? const Color(0xFF3F1429) : const Color(0xFFFCE7F3),
        };
      case 'health':
        return {
          'icon': Icons.favorite_border_rounded,
          'color': const Color(0xFF10B981),
          'bg': isDark ? const Color(0xFF093725) : const Color(0xFFD1FAE5),
        };
      case 'shopping':
        return {
          'icon': Icons.shopping_bag_outlined,
          'color': AppTheme.amber,
          'bg': isDark ? const Color(0xFF3B2B0A) : AppTheme.amberSoft,
        };
      default:
        return {
          'icon': Icons.receipt_long_rounded,
          'color': isDark ? AppTheme.inkMutedDark : AppTheme.inkMutedLight,
          'bg': isDark ? AppTheme.cardDarkElevated : const Color(0xFFF1F5F9),
        };
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _formatAmount(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final meta = categoryDetails(entry.category, isDark);
    final icon = meta['icon'] as IconData;
    final iconColor = meta['color'] as Color;
    final iconBg = meta['bg'] as Color;

    final cardContent = GlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.cardDarkElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.inkMutedDark
                              : AppTheme.inkMutedLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.inkMutedDark
                            : AppTheme.inkMutedLight,
                      ),
                    ),
                  ],
                ),
                if (entry.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$currency${_formatAmount(entry.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              letterSpacing: -0.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('expense-${entry.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.heavyImpact();
        onDelete?.call();
        return true;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.rose,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: BouncingTap(onTap: onTap, child: cardContent),
    );
  }
}
