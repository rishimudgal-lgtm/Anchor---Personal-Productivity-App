import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import 'animations.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.state,
    this.onEditBudget,
    this.onSelectCategory,
  });

  final HubState state;
  final VoidCallback? onEditBudget;
  final void Function(String category)? onSelectCategory;

  String _formatAmount(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpenses = state.expenses.where(
      (e) => e.date.year == now.year && e.date.month == now.month,
    );
    final spent = monthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final budget = state.monthlyBudget;
    final currency = state.currency;
    final remaining = budget - spent;
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status color
    final Color progressColor;
    final String statusText;
    if (spent > budget) {
      progressColor = AppTheme.rose;
      statusText = 'Over budget by $currency${_formatAmount(spent - budget)}';
    } else if (progress > 0.8) {
      progressColor = AppTheme.amber;
      statusText =
          '$currency${_formatAmount(remaining)} remaining (Critical 80%+)';
    } else {
      progressColor = AppTheme.primaryLight;
      statusText =
          '$currency${_formatAmount(remaining)} remaining of $currency${_formatAmount(budget)}';
    }

    // Category breakdown
    final Map<String, double> categorySums = {};
    for (final e in monthExpenses) {
      categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
    }
    final sortedCategories = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      elevated: true,
      glow: progress > 0.8,
      glowColor: spent > budget ? AppTheme.rose : AppTheme.amber,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Budget',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: spent > budget
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: spent > budget
                              ? AppTheme.rose
                              : (isDark
                                    ? AppTheme.inkMutedDark
                                    : AppTheme.inkMutedLight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              FilledButton.tonal(
                onPressed: onEditBudget,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                child: const Text('Adjust'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Numbers row with animated count-up!
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedCountUp(
                value: spent,
                prefix: currency,
                decimals: spent == spent.roundToDouble() ? 0 : 2,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ $currency${_formatAmount(budget)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.inkMutedDark
                      : AppTheme.inkMutedLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: isDark ? 0.2 : 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: progressColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% USED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: progressColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated progress bar
          AnimatedProgressBar(
            progress: progress,
            height: 10,
            color: progressColor,
          ),

          // Interactive Category distribution pills
          if (sortedCategories.isNotEmpty) ...[
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sortedCategories.take(5).map((entry) {
                  final pct = spent > 0
                      ? (entry.value / spent * 100).round()
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: BouncingTap(
                      onTap: onSelectCategory != null
                          ? () => onSelectCategory!(entry.key)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.cardDarkElevated
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.borderGlassDark
                                : AppTheme.borderGlassLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.inkDark
                                    : AppTheme.inkLight,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$pct%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
