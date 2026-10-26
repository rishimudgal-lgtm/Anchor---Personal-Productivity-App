import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../models.dart';
import '../reminder_service.dart';
import 'animations.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
    this.onToggleReminder,
    this.onPriorityCycle,
    this.onReschedule,
    this.showDate = false,
    this.overdue = false,
  });

  final HubTask task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleReminder;
  final void Function(int newPriority)? onPriorityCycle;
  final void Function(DateTime newDate)? onReschedule;
  final bool showDate;
  final bool overdue;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _expanded = false;

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

  String _relativeDueString(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    final diff = target.difference(today).inDays;

    if (diff < 0) return '${-diff}d overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'in ${diff}d';
    return _formatDate(d);
  }

  void _cyclePriority() {
    HapticFeedback.selectionClick();
    final next = (widget.task.priority + 1) % 3;
    widget.onPriorityCycle?.call(next);
  }

  void _showQuickRescheduleMenu(BuildContext context) {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reschedule Due Date',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.today_rounded,
                  color: AppTheme.primary,
                ),
                title: const Text('Today'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReschedule?.call(dateOnly);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.wb_sunny_outlined,
                  color: AppTheme.skyAccent,
                ),
                title: const Text('Tomorrow'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReschedule?.call(
                    dateOnly.add(const Duration(days: 1)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.next_week_outlined,
                  color: AppTheme.violet,
                ),
                title: const Text('Next Week (+7 Days)'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onReschedule?.call(
                    dateOnly.add(const Duration(days: 7)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isPastDue =
        widget.overdue ||
        (!widget.task.isDone &&
            DateTime(
              widget.task.dueDate.year,
              widget.task.dueDate.month,
              widget.task.dueDate.day,
            ).isBefore(DateTime(now.year, now.month, now.day)));

    // Priority styling
    final Color priorityBg;
    final Color priorityFg;
    final String priorityLabel;
    final IconData priorityIcon;
    switch (widget.task.priority) {
      case 2:
        priorityBg = isDark ? const Color(0xFF451A1A) : AppTheme.roseSoft;
        priorityFg = AppTheme.rose;
        priorityLabel = 'High';
        priorityIcon = Icons.priority_high_rounded;
        break;
      case 0:
        priorityBg = isDark
            ? AppTheme.cardDarkElevated
            : const Color(0xFFF1F5F9);
        priorityFg = isDark ? AppTheme.inkMutedDark : AppTheme.inkMutedLight;
        priorityLabel = 'Low';
        priorityIcon = Icons.south_rounded;
        break;
      default:
        priorityBg = isDark ? AppTheme.cardDarkElevated : AppTheme.iceBlue;
        priorityFg = isDark ? AppTheme.primaryLight : AppTheme.primary;
        priorityLabel = 'Normal';
        priorityIcon = Icons.circle_rounded;
    }

    final cardContent = GlassCard(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // High-Tech Animated Checkbox
              Semantics(
                button: true,
                toggled: widget.task.isDone,
                label:
                    '${widget.task.isDone ? 'Mark incomplete' : 'Mark complete'}: ${widget.task.title}',
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: BouncingTap(
                    onTap: widget.onToggle,
                    child: CompletionBurst(
                      trigger: widget.task.isDone,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: widget.task.isDone
                              ? AppTheme.skyGradient
                              : null,
                          color: widget.task.isDone
                              ? null
                              : (isDark ? Colors.transparent : Colors.white),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.task.isDone
                                ? Colors.transparent
                                : (isDark
                                      ? AppTheme.borderGlassDark
                                      : const Color(0xFFCBD5E1)),
                            width: 1.8,
                          ),
                          boxShadow: widget.task.isDone
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: widget.task.isDone
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Meta details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        decoration: widget.task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.task.isDone
                            ? (isDark
                                  ? AppTheme.inkMutedDark
                                  : AppTheme.inkMutedLight)
                            : (isDark ? AppTheme.inkDark : AppTheme.inkLight),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (widget.task.subject.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.cardDarkElevated
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.task.subject,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.inkMutedDark
                                    : AppTheme.inkMutedLight,
                              ),
                            ),
                          ),

                        // Interactive Due Date Chip
                        GestureDetector(
                          onTap: widget.onReschedule != null
                              ? () => _showQuickRescheduleMenu(context)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPastDue
                                  ? (isDark
                                        ? const Color(0xFF451A1A)
                                        : AppTheme.roseSoft)
                                  : (isDark
                                        ? AppTheme.cardDarkElevated
                                        : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPastDue
                                      ? Icons.error_outline_rounded
                                      : Icons.schedule_rounded,
                                  size: 11,
                                  color: isPastDue
                                      ? AppTheme.rose
                                      : (isDark
                                            ? AppTheme.inkMutedDark
                                            : AppTheme.inkMutedLight),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _relativeDueString(widget.task.dueDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isPastDue
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isPastDue
                                        ? AppTheme.rose
                                        : (isDark
                                              ? AppTheme.inkMutedDark
                                              : AppTheme.inkMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Interactive Priority Badge (Tap to cycle)
              if (!widget.task.isDone)
                BouncingTap(
                  onTap: widget.onPriorityCycle != null ? _cyclePriority : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: priorityFg.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 12, color: priorityFg),
                        const SizedBox(width: 4),
                        Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: priorityFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Expand notes toggle
              if (widget.task.notes.trim().isNotEmpty)
                IconButton(
                  tooltip: _expanded ? 'Hide notes' : 'Show notes',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),

              // Reminder Icon
              if (widget.onToggleReminder != null &&
                  ReminderService.instance.supportsScheduledReminders &&
                  !widget.task.isDone)
                IconButton(
                  iconSize: 19,
                  visualDensity: VisualDensity.compact,
                  tooltip: widget.task.reminderEnabled
                      ? 'Reminder on'
                      : 'Set reminder',
                  onPressed: widget.onToggleReminder,
                  icon: Icon(
                    widget.task.reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: widget.task.reminderEnabled
                        ? AppTheme.primaryLight
                        : (isDark
                              ? AppTheme.inkMutedDark
                              : AppTheme.inkMutedLight),
                  ),
                ),
            ],
          ),

          // Smoothly Animated Expandable Notes Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: widget.task.notes.trim().isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10, left: 38),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.cardDarkElevated
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.task.notes,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? AppTheme.inkDark : AppTheme.inkLight,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );

    // Dismissible wrapper for swipe gestures
    return Dismissible(
      key: ValueKey('task-${widget.task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onToggle();
          HapticFeedback.mediumImpact();
          return false;
        } else {
          HapticFeedback.heavyImpact();
          widget.onDelete?.call();
          return true;
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.done_all_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Toggle Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.rose,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      child: BouncingTap(onTap: widget.onTap, child: cardContent),
    );
  }
}
