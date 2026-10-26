import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../models.dart';
import '../widgets/animations.dart';
import '../widgets/empty_state.dart';
import '../widgets/feature_artwork.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, required this.state});

  final HubState state;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  late DateTime _selectedDate;
  String _query = '';
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  DateTime get _weekStart =>
      _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduled = state.habits
        .where((habit) => habit.isScheduledOn(_selectedDate))
        .toList();
    final visible =
        state.habits.where((habit) {
          if (!_showAll && !habit.isScheduledOn(_selectedDate)) return false;
          final q = _query.trim().toLowerCase();
          if (q.isEmpty) return true;
          return habit.title.toLowerCase().contains(q) ||
              habit.category.toLowerCase().contains(q) ||
              habit.steps.any((step) => step.toLowerCase().contains(q));
        }).toList()..sort((a, b) {
          final aDone = a.isCompleteOn(_selectedDate);
          final bDone = b.isCompleteOn(_selectedDate);
          if (aDone != bDone) return aDone ? 1 : -1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
    final completed = scheduled
        .where((habit) => habit.isCompleteOn(_selectedDate))
        .length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habits & Routines',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text('Small steps, repeated on your schedule.'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _showEditor(context, state),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _weekPicker(isDark),
                  const SizedBox(height: 14),
                  _dailyProgress(isDark, completed, scheduled.length),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Find a habit or routine',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      label: Text(
                        'Show habits not scheduled today',
                        style: TextStyle(
                          color: isDark ? AppTheme.inkDark : AppTheme.inkLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: _showAll,
                      backgroundColor: isDark
                          ? AppTheme.cardDarkElevated
                          : Colors.white,
                      selectedColor: isDark
                          ? AppTheme.primary.withValues(alpha: 0.22)
                          : AppTheme.iceBlue,
                      side: BorderSide(
                        color: isDark
                            ? AppTheme.borderDark
                            : AppTheme.borderLight,
                      ),
                      checkmarkColor: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primary,
                      onSelected: (value) => setState(() => _showAll = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: EmptyState(
                  icon: _query.isEmpty
                      ? Icons.track_changes_rounded
                      : Icons.search_off_rounded,
                  artworkColor: AppTheme.primary,
                  title: _query.isNotEmpty
                      ? 'No matching habits'
                      : state.habits.isEmpty
                      ? 'Start with one small habit'
                      : 'Nothing scheduled for this day',
                  message: _query.isNotEmpty
                      ? 'Try a different name, category, or routine step.'
                      : state.habits.isEmpty
                      ? 'Add a habit or turn a morning routine into a few easy check-ins.'
                      : 'Choose another day or show habits that are not scheduled today.',
                  actionLabel: state.habits.isEmpty
                      ? 'Add your first habit'
                      : null,
                  onAction: state.habits.isEmpty
                      ? () => _showEditor(context, state)
                      : null,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideTransition(
                    delay: Duration(milliseconds: 35 * index),
                    child: _HabitCard(
                      habit: visible[index],
                      date: _selectedDate,
                      weekStart: _weekStart,
                      isDark: isDark,
                      onToggle: () => state.toggleHabitCompletion(
                        visible[index],
                        _selectedDate,
                      ),
                      onToggleStep: (step) => state.toggleRoutineStep(
                        visible[index],
                        _selectedDate,
                        step,
                      ),
                      onEdit: () =>
                          _showEditor(context, state, existing: visible[index]),
                      onDelete: () =>
                          _confirmDelete(context, state, visible[index]),
                    ),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 112)),
        ],
      ),
    );
  }

  Widget _weekPicker(bool isDark) {
    final month = _selectedDate.toLocal();
    final monthName = _monthName(month.month);
    return Semantics(
      label: 'Week of ${_monthName(_weekStart.month)} ${_weekStart.day}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              '$monthName ${month.year}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Row(
            children: List.generate(7, (index) {
              final date = _weekStart.add(Duration(days: index));
              final selected = _sameDay(date, _selectedDate);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label:
                        '${_weekdayLabels[index]}, ${_monthName(date.month)} ${date.day}${selected ? ', selected' : ''}',
                    child: Material(
                      color: selected
                          ? AppTheme.primary
                          : (isDark ? AppTheme.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => setState(() => _selectedDate = date),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ExcludeSemantics(
                            child: Column(
                              children: [
                                Text(
                                  _weekdayLabels[index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white70
                                        : (isDark
                                              ? AppTheme.inkMutedDark
                                              : AppTheme.inkMutedLight),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: selected ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _dailyProgress(bool isDark, int completed, int total) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Semantics(
      label: 'Daily habit progress: $completed of $total complete',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isDark
              ? AppTheme.darkGlassGradient
              : AppTheme.iceGlassGradient,
          border: Border.all(
            color: isDark
                ? AppTheme.borderGlassDark
                : AppTheme.borderGlassLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.track_changes_rounded,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '$completed of $total complete',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: AnimatedProgressBar(
                progress: progress,
                height: 9,
                gradient: AppTheme.skyGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    HubState state, {
    HabitEntry? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HabitEditorSheet(state: state, existing: existing),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Habit added.' : 'Changes saved.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    HubState state,
    HabitEntry habit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this habit?'),
        content: Text(
          '“${habit.title}” and its saved completion history will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.deleteHabit(habit.id);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int month) => const [
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
  ][month - 1];
}

class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({required this.state, this.existing});

  final HubState state;
  final HabitEntry? existing;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _stepsController;
  late final Set<int> _days;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _categoryController = TextEditingController(
      text: existing?.category ?? 'Personal',
    );
    _stepsController = TextEditingController(
      text: existing?.steps.join('\n') ?? '',
    );
    _days = existing == null || existing.scheduleDays.isEmpty
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : existing.scheduleDays.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a name first.')));
      return;
    }

    setState(() => _saving = true);
    final steps = _stepsController.text
        .split('\n')
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();
    try {
      final existing = widget.existing;
      if (existing == null) {
        await widget.state.addHabit(
          title: title,
          category: _categoryController.text,
          scheduleDays: _days.toList()..sort(),
          steps: steps,
        );
      } else {
        await widget.state.updateHabit(
          existing.copyWith(
            title: title,
            category: _categoryController.text.trim().isEmpty
                ? 'Personal'
                : _categoryController.text.trim(),
            scheduleDays: _days.toList()..sort(),
            steps: steps,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          4,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing == null
                    ? 'Add a habit or routine'
                    : 'Edit habit or routine',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Morning reset',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Personal, Health, Study…',
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Repeat on',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  return FilterChip(
                    label: Text(_weekdayLabels[index]),
                    selected: _days.contains(day),
                    onSelected: _saving
                        ? null
                        : (selected) => setState(() {
                            selected ? _days.add(day) : _days.remove(day);
                          }),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                'Leave every day selected for a daily habit.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _stepsController,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Routine steps (optional)',
                  hintText:
                      'Drink water\nStretch for five minutes\nReview today’s plan',
                  helperText:
                      'Add one step per line. Leave blank for a single check-in.',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(existing == null ? 'Save habit' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.date,
    required this.weekStart,
    required this.isDark,
    required this.onToggle,
    required this.onToggleStep,
    required this.onEdit,
    required this.onDelete,
  });

  final HabitEntry habit;
  final DateTime date;
  final DateTime weekStart;
  final bool isDark;
  final VoidCallback onToggle;
  final ValueChanged<int> onToggleStep;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = habit.isCompleteOn(date);
    final checkedSteps = habit.completedStepCountOn(date);
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final scheduledDays = weekDays.where(habit.isScheduledOn).toList();
    final weekComplete = scheduledDays.where(habit.isCompleteOn).length;
    return GlassCard(
      elevated: complete,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FeatureArtwork(
                icon: habit.steps.isEmpty
                    ? Icons.flag_rounded
                    : Icons.checklist_rounded,
                color: habit.steps.isEmpty ? AppTheme.primary : AppTheme.violet,
                size: 42,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.category} · $weekComplete/${scheduledDays.length} this week',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.inkMutedDark
                            : AppTheme.inkMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (habit.steps.isEmpty)
                Semantics(
                  label:
                      '${complete ? 'Mark ${habit.title} incomplete' : 'Mark ${habit.title} complete'} for ${_dateLabel(date)}',
                  child: Checkbox(
                    value: complete,
                    onChanged: (_) => onToggle(),
                  ),
                )
              else
                Tooltip(
                  message: complete
                      ? 'Reset routine for ${_dateLabel(date)}'
                      : 'Complete all routine steps',
                  child: IconButton(
                    onPressed: onToggle,
                    icon: Icon(
                      complete
                          ? Icons.restart_alt_rounded
                          : Icons.done_all_rounded,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Habit options for ${habit.title}',
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (habit.steps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$checkedSteps of ${habit.steps.length} steps',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.inkMutedDark
                            : AppTheme.inkMutedLight,
                      ),
                    ),
                  ),
                  Text(
                    complete ? 'Routine done' : 'Routine',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: complete ? AppTheme.emerald : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < habit.steps.length; index++)
              Semantics(
                label:
                    '${habit.steps[index]}, step ${index + 1} of ${habit.steps.length}, ${habit.completedStepsByDate[habitDateKey(date)]?.contains(index) == true ? 'complete' : 'not complete'}',
                child: CheckboxListTile(
                  contentPadding: const EdgeInsets.only(left: 2),
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: -3,
                    vertical: -3,
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    habit.steps[index],
                    style: TextStyle(
                      decoration:
                          habit.completedStepsByDate[habitDateKey(date)]
                                  ?.contains(index) ==
                              true
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  value:
                      habit.completedStepsByDate[habitDateKey(date)]?.contains(
                        index,
                      ) ==
                      true,
                  onChanged: (_) => onToggleStep(index),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _dateLabel(DateTime value) => '${value.month}/${value.day}';
}
