import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../models.dart';
import '../widgets/animations.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';
import '../widgets/undo_delete.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key, required this.state});

  final HubState state;

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  String _searchQuery = '';
  String _selectedSubject = 'All';
  bool _calendarMode = false;
  DateTime _selectedDay = DateTime.now();
  DateTime _visibleMonth = DateTime.now();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final today = _dateOnly(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter open tasks
    var openTasks = state.tasks.where((t) => !t.isDone).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      openTasks = openTasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.subject.toLowerCase().contains(q) ||
                t.notes.toLowerCase().contains(q),
          )
          .toList();
    }

    // Subject filter
    final subjects = {
      'All',
      ...state.tasks.map((t) => t.subject.trim()).where((s) => s.isNotEmpty),
    }.toList();

    if (_selectedSubject != 'All') {
      openTasks = openTasks
          .where((t) => t.subject == _selectedSubject)
          .toList();
    }

    final overdue = openTasks
        .where((t) => _dateOnly(t.dueDate).isBefore(today))
        .toList();
    final future = openTasks
        .where((t) => _dateOnly(t.dueDate).isAfter(today))
        .toList();

    final weekEnd = today.add(const Duration(days: 7));
    final nextWeek = future
        .where((t) => !_dateOnly(t.dueDate).isAfter(weekEnd))
        .toList();
    final later = future
        .where((t) => _dateOnly(t.dueDate).isAfter(weekEnd))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientScaffoldBackground(
        child: CustomScrollView(
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
                      'Timeline & Milestones',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Past due deadlines, next 7 days, and future horizons',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.inkMutedDark
                            : AppTheme.inkMutedLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Timeline'),
                          icon: Icon(Icons.view_agenda_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Calendar'),
                          icon: Icon(Icons.calendar_month_outlined),
                        ),
                      ],
                      selected: {_calendarMode},
                      onSelectionChanged: (selection) =>
                          setState(() => _calendarMode = selection.first),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search upcoming milestones...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => _searchQuery = ''),
                              )
                            : null,
                      ),
                    ),

                    // Subject filter pills
                    if (subjects.length > 2) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: subjects.map((subj) {
                            final isSel = _selectedSubject == subj;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(subj),
                                selected: isSel,
                                onSelected: (val) {
                                  if (val)
                                    setState(() => _selectedSubject = subj);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_calendarMode)
              ..._buildCalendarSlivers(context, openTasks, today, isDark)
            // Empty state if nothing upcoming
            else if (overdue.isEmpty && future.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: EmptyState(
                    icon: Icons.event_available_rounded,
                    artworkColor: AppTheme.violet,
                    title: _searchQuery.isNotEmpty
                        ? 'No matching milestones'
                        : 'No upcoming tasks',
                    message: _searchQuery.isNotEmpty
                        ? 'Try searching with different keywords.'
                        : 'Your future schedule is clear. Plan ahead to keep momentum.',
                    actionLabel: 'Schedule Milestone',
                    onAction: () => showTaskDialog(context, state),
                  ),
                ),
              )
            else ...[
              // Overdue Section
              if (overdue.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppTheme.rose,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Past Due (${overdue.length})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.rose,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          onPressed: () async {
                            for (final t in overdue) {
                              await state.updateTask(
                                t.copyWith(dueDate: today),
                              );
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Moved overdue tasks to today!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.today_rounded, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Move to today',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = overdue[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideTransition(
                          delay: Duration(milliseconds: 25 * index),
                          child: TaskCard(
                            task: task,
                            overdue: true,
                            showDate: true,
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
                    }, childCount: overdue.length),
                  ),
                ),
              ],

              // Next 7 Days Section
              if (nextWeek.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next 7 Days (${nextWeek.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = nextWeek[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideTransition(
                          delay: Duration(milliseconds: 25 * index),
                          child: TaskCard(
                            task: task,
                            showDate: true,
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
                    }, childCount: nextWeek.length),
                  ),
                ),
              ],

              // Later Section
              if (later.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.inkMutedDark
                                : AppTheme.inkMutedLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Later (${later.length})',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = later[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideTransition(
                          delay: Duration(milliseconds: 25 * index),
                          child: TaskCard(
                            task: task,
                            showDate: true,
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
                    }, childCount: later.length),
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCalendarSlivers(
    BuildContext context,
    List<HubTask> tasks,
    DateTime today,
    bool isDark,
  ) {
    final monthStart = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );
    final selected = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final selectedTasks = tasks.where((task) {
      final date = task.dueDate;
      return date.year == selected.year &&
          date.month == selected.month &&
          date.day == selected.day;
    }).toList();
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: GlassCard(
            elevated: true,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month - 1,
                        );
                        _selectedDay = _visibleMonth;
                      }),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '${months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () => setState(() {
                        _visibleMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                        );
                        _selectedDay = _visibleMonth;
                      }),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _visibleMonth = today;
                        _selectedDay = today;
                      }),
                      child: const Text('Today'),
                    ),
                  ],
                ),
                Row(
                  children: weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppTheme.inkMutedDark
                                    : AppTheme.inkMutedLight,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    final day = gridStart.add(Duration(days: index));
                    final dayTasks = tasks
                        .where(
                          (task) =>
                              task.dueDate.year == day.year &&
                              task.dueDate.month == day.month &&
                              task.dueDate.day == day.day,
                        )
                        .length;
                    final isCurrentMonth = day.month == _visibleMonth.month;
                    final isSelected =
                        day.year == selected.year &&
                        day.month == selected.month &&
                        day.day == selected.day;
                    final isToday =
                        day.year == today.year &&
                        day.month == today.month &&
                        day.day == today.day;
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : null,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: AppTheme.primary,
                                    width: 1.3,
                                  )
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: !isCurrentMonth
                                      ? (isDark
                                                ? AppTheme.inkMutedDark
                                                : AppTheme.inkMutedLight)
                                            .withValues(alpha: 0.5)
                                      : isSelected
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (dayTasks > 0)
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${months[selected.month - 1]} ${selected.day} · ${selectedTasks.length} task${selectedTasks.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Add task for this date',
                onPressed: () => showTaskDialog(
                  context,
                  widget.state,
                  initialDueDate: selected,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ),
      if (selectedTasks.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: EmptyState(
              icon: Icons.event_available_rounded,
              artworkColor: AppTheme.amber,
              title: 'Nothing planned for this day',
              message: 'Add a task to see it on your calendar.',
              actionLabel: 'Add Task',
              onAction: () => showTaskDialog(
                context,
                widget.state,
                initialDueDate: selected,
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final task = selectedTasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TaskCard(
                  task: task,
                  showDate: true,
                  onToggle: () => widget.state.toggleTask(task),
                  onTap: () =>
                      showTaskDialog(context, widget.state, existingTask: task),
                  onDelete: () =>
                      deleteTaskWithUndo(context, widget.state, task),
                  onToggleReminder: () => widget.state.toggleTaskReminder(task),
                  onPriorityCycle: (priority) => widget.state.updateTask(
                    task.copyWith(priority: priority),
                  ),
                  onReschedule: (date) =>
                      widget.state.updateTask(task.copyWith(dueDate: date)),
                ),
              );
            }, childCount: selectedTasks.length),
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 150)),
    ];
  }
}
