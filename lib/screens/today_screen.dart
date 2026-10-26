import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../widgets/animations.dart';
import '../widgets/brand_mark.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/task_card.dart';
import '../widgets/undo_delete.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.state, this.onOpenManageTab});

  final HubState state;
  final ValueChanged<int>? onOpenManageTab;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _taskFilter = 0; // 0: All, 1: Pending, 2: Completed

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_twilight_rounded;
    return Icons.bedtime_rounded;
  }

  String _longDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatAmount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayTasks =
        state.tasks.where((task) => _sameDay(task.dueDate, now)).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));

    final totalToday = todayTasks.length;
    final doneToday = todayTasks.where((t) => t.isDone).length;
    final completionPct = totalToday > 0 ? doneToday / totalToday : 0.0;

    final monthSpend = state.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0.0, (sum, e) => sum + e.amount);

    final expiringSoon = state.pantry.where((entry) {
      final days = _daysBetween(now, entry.expiryDate);
      return days >= 0 && days <= 3;
    }).length;

    // Filter tasks
    final filteredTasks = todayTasks.where((t) {
      if (_taskFilter == 1) return !t.isDone;
      if (_taskFilter == 2) return t.isDone;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientScaffoldBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Executive App Bar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const BrandMark(size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _greetingIcon(),
                                      color: AppTheme.amber,
                                      size: 17,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _greeting().toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: isDark
                                            ? AppTheme.primaryLight
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _longDate(now),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppTheme.inkMutedDark
                                        : AppTheme.inkMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Theme Quick-Toggle Button
                    IconButton.filledTonal(
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 19,
                      ),
                      tooltip: isDark
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
                      onPressed: () {
                        state.setThemeMode(isDark ? 'light' : 'dark');
                      },
                    ),
                    const SizedBox(width: 8),
                    // Settings Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.tune_rounded, size: 19),
                      tooltip: 'Preferences & Settings',
                      onPressed: () => showSettingsSheet(context, state),
                    ),
                  ],
                ),
              ),
            ),

            // Daily Progress Hero Banner with Ambient Glow
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: FadeSlideTransition(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroSkyGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                          blurRadius: 16,
                          spreadRadius: 1,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "DAILY MOMENTUM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$doneToday of $totalToday finished',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          totalToday == 0
                              ? 'Your schedule is clear. Plan key priorities or launch a focus sprint.'
                              : doneToday == totalToday
                              ? '🎉 100% of daily targets finished. Outstanding focus!'
                              : 'You have ${totalToday - doneToday} priority item${(totalToday - doneToday) > 1 ? 's' : ''} left for today.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Smooth Progress Bar
                        AnimatedProgressBar(
                          progress: completionPct,
                          height: 8,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2x2 Metric Cards Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FadeSlideTransition(
                        delay: const Duration(milliseconds: 60),
                        child: MetricCard(
                          label: 'Tasks Today',
                          value: '$totalToday',
                          icon: Icons.checklist_rounded,
                          color: AppTheme.primaryLight,
                          subtitle: '$doneToday done',
                          onTap: () => setState(() => _taskFilter = 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeSlideTransition(
                        delay: const Duration(milliseconds: 120),
                        child: MetricCard(
                          label: 'Completion',
                          value: '${(completionPct * 100).toInt()}%',
                          icon: Icons.task_alt_rounded,
                          color: AppTheme.electricCyan,
                          subtitle: doneToday == totalToday && totalToday > 0
                              ? 'All clear'
                              : 'In progress',
                          onTap: () => setState(() => _taskFilter = 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mini Insight Cards (Expenses & Pantry)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: FadeSlideTransition(
                        delay: const Duration(milliseconds: 180),
                        child: MetricCard(
                          label: 'Month Spend',
                          value:
                              '${state.currency}${_formatAmount(monthSpend)}',
                          icon: Icons.account_balance_wallet_outlined,
                          color: AppTheme.amber,
                          subtitle:
                              'Target: ${state.currency}${_formatAmount(state.monthlyBudget)}',
                          onTap: () => widget.onOpenManageTab?.call(1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeSlideTransition(
                        delay: const Duration(milliseconds: 240),
                        child: MetricCard(
                          label: 'Pantry Watch',
                          value: '$expiringSoon items',
                          icon: Icons.inventory_2_outlined,
                          color: expiringSoon > 0
                              ? AppTheme.rose
                              : AppTheme.primaryLight,
                          subtitle: expiringSoon > 0 ? 'Use soon' : 'Optimal',
                          onTap: () => widget.onOpenManageTab?.call(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Plan Header & Segmented Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Agenda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          '${filteredTasks.length} item${filteredTasks.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppTheme.inkMutedDark
                                : AppTheme.inkMutedLight,
                          ),
                        ),
                      ],
                    ),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: 0, label: Text('All')),
                        ButtonSegment(value: 1, label: Text('Open')),
                        ButtonSegment(value: 2, label: Text('Done')),
                      ],
                      selected: {_taskFilter},
                      onSelectionChanged: (val) =>
                          setState(() => _taskFilter = val.first),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Tasks List
            if (filteredTasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: EmptyState(
                    icon: Icons.event_available_rounded,
                    title: _taskFilter == 2
                        ? 'No completed tasks yet'
                        : _taskFilter == 1
                        ? 'No open tasks for today'
                        : 'Clear day ahead',
                    message: _taskFilter == 2
                        ? 'Check off tasks as you finish them to see them here.'
                        : 'Schedule an assignment or priority milestone to get started.',
                    actionLabel: 'Schedule Priority',
                    onAction: () => showTaskDialog(context, state),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final task = filteredTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FadeSlideTransition(
                        delay: Duration(milliseconds: 25 * index),
                        child: TaskCard(
                          task: task,
                          onToggle: () => state.toggleTask(task),
                          onTap: () => showTaskDialog(
                            context,
                            state,
                            existingTask: task,
                          ),
                          onDelete: () =>
                              deleteTaskWithUndo(context, state, task),
                          onToggleReminder: () =>
                              state.toggleTaskReminder(task),
                          onPriorityCycle: (newP) {
                            state.updateTask(task.copyWith(priority: newP));
                          },
                          onReschedule: (newDate) {
                            state.updateTask(task.copyWith(dueDate: newDate));
                          },
                        ),
                      ),
                    );
                  }, childCount: filteredTasks.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }
}
