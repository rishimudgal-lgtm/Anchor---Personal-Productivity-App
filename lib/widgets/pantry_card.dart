import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../models.dart';
import '../reminder_service.dart';
import 'animations.dart';

class PantryCard extends StatelessWidget {
  const PantryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
    this.onToggleReminder,
    this.onConsume,
    this.onAdjustQuantity,
    this.onAddToShopping,
  });

  final PantryEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleReminder;
  final VoidCallback? onConsume;
  final void Function(int delta)? onAdjustQuantity;
  final VoidCallback? onAddToShopping;

  int _daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(target.year, target.month, target.day);
    return d.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = _daysUntil(entry.expiryDate);
    final quantityMatch = RegExp(
      r'^(\s*)(\d+)(.*)$',
    ).firstMatch(entry.quantity);
    final quantityValue = quantityMatch == null
        ? null
        : int.tryParse(quantityMatch.group(2)!);

    // Freshness indicator
    final Color badgeBg;
    final Color badgeFg;
    final String statusText;
    final IconData statusIcon;

    if (days < 0) {
      badgeBg = isDark ? const Color(0xFF451A1A) : AppTheme.roseSoft;
      badgeFg = AppTheme.rose;
      statusText = days == -1 ? 'Expired yesterday' : 'Expired ${-days}d ago';
      statusIcon = Icons.error_outline_rounded;
    } else if (days == 0) {
      badgeBg = isDark ? const Color(0xFF451A1A) : AppTheme.roseSoft;
      badgeFg = AppTheme.rose;
      statusText = 'Expires today';
      statusIcon = Icons.warning_amber_rounded;
    } else if (days <= 3) {
      badgeBg = isDark ? const Color(0xFF3B2B0A) : AppTheme.amberSoft;
      badgeFg = AppTheme.amber;
      statusText = 'Use in ${days}d';
      statusIcon = Icons.timelapse_rounded;
    } else {
      badgeBg = isDark ? AppTheme.cardDarkElevated : AppTheme.iceBlue;
      badgeFg = isDark ? AppTheme.primaryLight : AppTheme.primary;
      statusText = 'Fresh (${days}d)';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    final cardContent = GlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Icon with ambient border
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDarkElevated : AppTheme.iceBlueSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: badgeFg.withValues(alpha: 0.25)),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: isDark ? AppTheme.primaryLight : AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (entry.quantity.isNotEmpty)
                      if (quantityValue != null && onAdjustQuantity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.cardDarkElevated
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Decrease quantity',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 24,
                                  height: 26,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                                onPressed: quantityValue > 0
                                    ? () => onAdjustQuantity!(-1)
                                    : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Text(
                                '${quantityMatch!.group(2)!}${quantityMatch.group(3)!}'
                                    .trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTheme.inkDark
                                      : AppTheme.inkLight,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Increase quantity',
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints.tightFor(
                                  width: 24,
                                  height: 26,
                                ),
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                                onPressed: () => onAdjustQuantity!(1),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        )
                      else
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
                            entry.quantity,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.inkDark
                                  : AppTheme.inkLight,
                            ),
                          ),
                        ),
                    if (entry.category.isNotEmpty)
                      Text(
                        entry.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.inkMutedDark
                              : AppTheme.inkMutedLight,
                        ),
                      ),
                  ],
                ),
                if (onAddToShopping != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAddToShopping,
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 15,
                      ),
                      label: const Text('Add to shopping'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        textStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Freshness badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: badgeFg.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: badgeFg),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeFg,
                  ),
                ),
              ],
            ),
          ),

          // Reminder Icon
          if (onToggleReminder != null &&
              ReminderService.instance.supportsScheduledReminders &&
              days >= 0)
            IconButton(
              iconSize: 19,
              visualDensity: VisualDensity.compact,
              tooltip: entry.reminderEnabled ? 'Reminder on' : 'Set reminder',
              onPressed: onToggleReminder,
              icon: Icon(
                entry.reminderEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: entry.reminderEnabled
                    ? AppTheme.primaryLight
                    : (isDark ? AppTheme.inkMutedDark : AppTheme.inkMutedLight),
              ),
            ),
          if (onConsume != null)
            IconButton(
              iconSize: 19,
              visualDensity: VisualDensity.compact,
              tooltip: 'Mark as used up',
              onPressed: onConsume,
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppTheme.emerald,
              ),
            ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('pantry-${entry.id}'),
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
