import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../widgets/animations.dart';
import '../widgets/interactive_timer.dart';
import '../widgets/metric_card.dart';
import '../widgets/dialogs.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});

  final HubState state;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _formatMinutes(int mins) {
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String _formatSessionDate(DateTime d) {
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
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = _mondayOf(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final completedThisWeek = state.tasks.where((t) {
      final date = t.completedAt;
      return t.isDone && date != null && !date.isBefore(weekStart);
    }).length;

    final weekSessions = state.sessions
        .where((s) => !s.date.isBefore(weekStart))
        .toList();

    final totalFocusMinutes = weekSessions.fold<int>(
      0,
      (sum, s) => sum + s.minutes,
    );

    final openTasks = state.tasks.where((t) => !t.isDone).length;

    // Daily breakdown Mon-Sun
    final byDay = List<int>.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      return state.sessions
          .where((s) => _sameDay(s.date, day))
          .fold<int>(0, (sum, s) => sum + s.minutes);
    });

    final maxMinutes = byDay.fold<int>(0, (max, v) => v > max ? v : max);

    // Recent sessions
    final recentSessions = state.sessions.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Focus minutes, weekly achievements, and active timer',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Metric Cards Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 60),
                      child: MetricCard(
                        label: 'Tasks Finished',
                        value: '$completedThisWeek',
                        icon: Icons.task_alt_rounded,
                        color: AppTheme.primaryLight,
                        subtitle: 'This week',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 120),
                      child: MetricCard(
                        label: 'Focus Time',
                        value: _formatMinutes(totalFocusMinutes),
                        icon: Icons.timer_outlined,
                        gradient: AppTheme.skyGradient,
                        subtitle: '$openTasks open tasks',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Interactive Pomodoro Timer Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GlassCard(
                elevated: true,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3B2B0A)
                                : AppTheme.amberSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppTheme.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.currentStreak} day streak',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Complete a task, habit, routine, or focus session to keep it going',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppTheme.inkMutedDark
                                      : AppTheme.inkMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit weekly goals',
                          onPressed: () =>
                              showWeeklyGoalsDialog(context, state),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _GoalProgressRow(
                      label: 'Tasks',
                      value: completedThisWeek,
                      goal: state.settings.weeklyTaskGoal,
                      suffix: 'done',
                    ),
                    const SizedBox(height: 13),
                    _GoalProgressRow(
                      label: 'Focus',
                      value: totalFocusMinutes,
                      goal: state.settings.weeklyFocusGoalMinutes,
                      suffix: 'min',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Interactive Pomodoro Timer Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 180),
                child: InteractiveTimerWidget(state: state),
              ),
            ),
          ),

          // Weekly Focus Bar Chart Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FadeSlideTransition(
                delay: const Duration(milliseconds: 240),
                child: GlassCard(
                  elevated: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Focus This Week',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Minutes spent in deep work per day',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppTheme.inkMutedDark
                                      : AppTheme.inkMutedLight,
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
                              color: isDark
                                  ? const Color(0xFF0C385C)
                                  : AppTheme.iceBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatMinutes(totalFocusMinutes),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppTheme.primaryLight
                                    : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      // Animated Week Bars
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (index) {
                            final val = byDay[index];
                            final barHeight = maxMinutes == 0
                                ? 8.0
                                : (75.0 * val / maxMinutes).clamp(8.0, 75.0);
                            final day = weekStart.add(Duration(days: index));
                            final isToday = _sameDay(day, now);
                            const daysLabels = [
                              'M',
                              'T',
                              'W',
                              'T',
                              'F',
                              'S',
                              'S',
                            ];

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    val > 0 ? '$val' : '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? AppTheme.primaryLight
                                          : (isDark
                                                ? AppTheme.inkMutedDark
                                                : AppTheme.inkMutedLight),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                    height: barHeight,
                                    width: 22,
                                    decoration: BoxDecoration(
                                      gradient: isToday
                                          ? AppTheme.skyGradient
                                          : null,
                                      color: isToday
                                          ? null
                                          : (isDark
                                                ? const Color(0xFF1E304F)
                                                : AppTheme.iceBlueMedium),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: isToday
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    daysLabels[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                      color: isToday
                                          ? AppTheme.primaryLight
                                          : (isDark
                                                ? AppTheme.inkMutedDark
                                                : AppTheme.inkMutedLight),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Recent Focus Sessions List
          if (recentSessions.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Text(
                  'Recent Focus History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final s = recentSessions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0C385C)
                                  : AppTheme.iceBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatSessionDate(s.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppTheme.inkMutedDark
                                        : AppTheme.inkMutedLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppTheme.skyGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${s.minutes} min',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: 'Remove',
                            onPressed: () => state.deleteFocusSession(s.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: recentSessions.take(10).length),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.label,
    required this.value,
    required this.goal,
    required this.suffix,
  });

  final String label;
  final int value;
  final int goal;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / goal).clamp(0.0, 1.0);
    final done = value >= goal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$label goal',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$value / $goal $suffix',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            if (done) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.emerald,
                size: 17,
              ),
            ],
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E304F)
                : AppTheme.iceBlue,
            color: done ? AppTheme.emerald : AppTheme.primary,
          ),
        ),
      ],
    );
  }
}
