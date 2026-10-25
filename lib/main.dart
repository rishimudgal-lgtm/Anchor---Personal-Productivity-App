import 'package:flutter/material.dart';

import 'hub_state.dart';
import 'models.dart';
import 'reminder_service.dart';

const _ink = Color(0xFF20312C);
const _green = Color(0xFF316B59);
const _mint = Color(0xFFE7F1EB);
const _paper = Color(0xFFF6F8F5);
const _amber = Color(0xFFF1B65F);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = ReminderService.instance;
  await reminders.initialize();
  final state = HubState(reminders: reminders);
  await state.load();
  runApp(MyManagementHub(state: state));
}

class MyManagementHub extends StatelessWidget {
  const MyManagementHub({super.key, required this.state});

  final HubState state;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: Brightness.light,
    ).copyWith(primary: _green, surface: Colors.white, onSurface: _ink);
    return MaterialApp(
      title: 'My Management Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: _paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _green, width: 1.4),
          ),
        ),
      ),
      home: HubShell(state: state),
    );
  }
}

class HubShell extends StatefulWidget {
  const HubShell({super.key, required this.state});

  final HubState state;

  @override
  State<HubShell> createState() => _HubShellState();
}

class _HubShellState extends State<HubShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: [
              TodayScreen(state: widget.state),
              UpcomingScreen(state: widget.state),
              ManageScreen(state: widget.state),
              ProgressScreen(state: widget.state),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.upcoming_outlined),
              selectedIcon: Icon(Icons.upcoming),
              label: 'Upcoming',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Manage',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Progress',
            ),
          ],
        ),
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayTasks =
        state.tasks.where((task) => _sameDay(task.dueDate, now)).toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
    final doneToday = state.tasks
        .where(
          (task) =>
              task.isDone &&
              task.completedAt != null &&
              _sameDay(task.completedAt!, now),
        )
        .length;
    final monthSpend = state.expenses
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final expiringSoon = state.pantry.where((entry) {
      final days = _daysBetween(now, entry.expiryDate);
      return days >= 0 && days <= 3;
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: _green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.1,
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _longDate(now),
                    style: TextStyle(
                      color: _ink.withValues(alpha: .62),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_outlined, color: _green),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Tasks today',
                value: '${todayTasks.length}',
                icon: Icons.checklist_rounded,
                tint: _mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Completed today',
                value: '$doneToday',
                icon: Icons.task_alt_rounded,
                tint: const Color(0xFFFFF1D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SectionHeading(
          title: 'Your plan',
          subtitle: 'What needs your attention today',
        ),
        const SizedBox(height: 12),
        if (todayTasks.isEmpty)
          const _EmptyCard(
            icon: Icons.event_available_outlined,
            title: 'A clear day',
            message: 'Add an assignment or task in Manage when you are ready.',
          )
        else
          ...todayTasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskTile(
                task: task,
                onToggle: () => state.toggleTask(task),
                onToggleReminder: () =>
                    _toggleTaskReminder(context, state, task),
              ),
            ),
          ),
        const SizedBox(height: 14),
        _SectionHeading(
          title: 'Keep in view',
          subtitle: 'A quick look across your week',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniInsight(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Spent this month',
                value: _amount(monthSpend),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniInsight(
                icon: Icons.inventory_2_outlined,
                label: 'Expiring in 3 days',
                value: '$expiringSoon items',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SoftNote(
          icon: Icons.lightbulb_outline_rounded,
          title: 'A little progress adds up',
          message:
              'Check off a task or log a focus session to see your progress grow.',
        ),
      ],
    );
  }
}

class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key, required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final openTasks = state.tasks.where((task) => !task.isDone).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final overdue = openTasks
        .where((task) => _dateOnly(task.dueDate).isBefore(today))
        .toList();
    final future = openTasks
        .where((task) => _dateOnly(task.dueDate).isAfter(today))
        .toList();
    final weekEnd = today.add(const Duration(days: 7));
    final nextWeek = future
        .where((task) => !_dateOnly(task.dueDate).isAfter(weekEnd))
        .toList();
    final later = future
        .where((task) => _dateOnly(task.dueDate).isAfter(weekEnd))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _PageIntro(
          title: 'Upcoming',
          subtitle: 'Past due, soon, and later deadlines',
        ),
        const SizedBox(height: 20),
        if (overdue.isEmpty && future.isEmpty)
          const _EmptyCard(
            icon: Icons.event_available_outlined,
            title: 'Nothing scheduled ahead',
            message: 'Your future tasks will appear here, sorted by due date.',
          )
        else ...[
          if (overdue.isNotEmpty) ...[
            _SectionHeading(
              title: 'Past due',
              subtitle: 'Bring these back into your plan',
            ),
            const SizedBox(height: 10),
            ...overdue.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  task: task,
                  onToggle: () => state.toggleTask(task),
                  overdue: true,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (nextWeek.isNotEmpty) ...[
            _SectionHeading(
              title: 'Next 7 days',
              subtitle: 'Starting tomorrow',
            ),
            const SizedBox(height: 10),
            ...nextWeek.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  task: task,
                  onToggle: () => state.toggleTask(task),
                  showDate: true,
                  onToggleReminder: () =>
                      _toggleTaskReminder(context, state, task),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (later.isNotEmpty) ...[
            _SectionHeading(
              title: 'Later',
              subtitle: 'More than a week from now',
            ),
            const SizedBox(height: 10),
            ...later.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TaskTile(
                  task: task,
                  onToggle: () => state.toggleTask(task),
                  showDate: true,
                  onToggleReminder: () =>
                      _toggleTaskReminder(context, state, task),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key, required this.state});
  final HubState state;

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _PageIntro(
          title: 'Manage',
          subtitle: 'Your plans, spending, and pantry',
        ),
        const SizedBox(height: 20),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 0,
              label: Text('Planner'),
              icon: Icon(Icons.checklist_rounded),
            ),
            ButtonSegment(
              value: 1,
              label: Text('Expenses'),
              icon: Icon(Icons.payments_outlined),
            ),
            ButtonSegment(
              value: 2,
              label: Text('Pantry'),
              icon: Icon(Icons.inventory_2_outlined),
            ),
          ],
          selected: {_section},
          onSelectionChanged: (selection) =>
              setState(() => _section = selection.first),
        ),
        const SizedBox(height: 22),
        if (_section == 0)
          _PlannerPanel(state: widget.state)
        else if (_section == 1)
          _ExpensePanel(state: widget.state)
        else
          _PantryPanel(state: widget.state),
      ],
    );
  }
}

class _PlannerPanel extends StatelessWidget {
  const _PlannerPanel({required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final tasks = state.tasks.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeading(
          title: 'Assignments & tasks',
          subtitle:
              '${state.tasks.where((task) => !task.isDone).length} still open',
          buttonLabel: 'Add task',
          icon: Icons.add_rounded,
          onPressed: () => _showTaskDialog(context, state),
        ),
        const SizedBox(height: 14),
        if (tasks.isEmpty)
          const _EmptyCard(
            icon: Icons.edit_calendar_outlined,
            title: 'Start with one task',
            message:
                'Add an assignment, deadline, or something you want to remember.',
          )
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskTile(
                task: task,
                onToggle: () => state.toggleTask(task),
                showDate: true,
                onToggleReminder: () =>
                    _toggleTaskReminder(context, state, task),
                onDelete: () => state.deleteTask(task.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpensePanel extends StatelessWidget {
  const _ExpensePanel({required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final entries = state.expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final monthTotal = entries
        .where(
          (entry) =>
              entry.date.year == now.year && entry.date.month == now.month,
        )
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricCard(
          label: 'Spent this month',
          value: _amount(monthTotal),
          icon: Icons.account_balance_wallet_outlined,
          tint: const Color(0xFFFFF1D8),
        ),
        const SizedBox(height: 18),
        _PanelHeading(
          title: 'Recent expenses',
          subtitle: '${entries.length} saved',
          buttonLabel: 'Add expense',
          icon: Icons.add_rounded,
          onPressed: () => _showExpenseDialog(context, state),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const _EmptyCard(
            icon: Icons.receipt_long_outlined,
            title: 'Keep a simple record',
            message:
                'Add purchases as they happen and see your monthly total here.',
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseTile(
                entry: entry,
                onDelete: () => state.deleteExpense(entry.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _PantryPanel extends StatelessWidget {
  const _PantryPanel({required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.pantry.toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final soon = entries.where((entry) {
      final days = _daysBetween(DateTime.now(), entry.expiryDate);
      return days >= 0 && days <= 3;
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricCard(
          label: 'Use soon',
          value: '$soon items',
          icon: Icons.timelapse_rounded,
          tint: const Color(0xFFFFF1D8),
        ),
        const SizedBox(height: 18),
        _PanelHeading(
          title: 'Pantry items',
          subtitle: '${entries.length} saved',
          buttonLabel: 'Add item',
          icon: Icons.add_rounded,
          onPressed: () => _showPantryDialog(context, state),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          const _EmptyCard(
            icon: Icons.kitchen_outlined,
            title: 'Know what you have',
            message:
                'Save an item and its expiry date to keep it on your radar.',
          )
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PantryTile(
                entry: entry,
                onDelete: () => state.deletePantryItem(entry.id),
                onToggleReminder: () =>
                    _togglePantryReminder(context, state, entry),
              ),
            ),
          ),
      ],
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});
  final HubState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = _mondayOf(now);
    final completed = state.tasks.where((task) {
      final date = task.completedAt;
      return task.isDone &&
          date != null &&
          !_dateOnly(date).isBefore(weekStart);
    }).length;
    final sessions = state.sessions
        .where((session) => !_dateOnly(session.date).isBefore(weekStart))
        .toList();
    final focusMinutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.minutes,
    );
    final openTasks = state.tasks.where((task) => !task.isDone).length;
    final byDay = List<int>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return state.sessions
          .where((session) => _sameDay(session.date, day))
          .fold<int>(0, (sum, session) => sum + session.minutes);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const _PageIntro(
          title: 'Progress',
          subtitle: 'Small steps, seen over time',
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Tasks completed',
                value: '$completed',
                icon: Icons.task_alt_rounded,
                tint: _mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Focus time',
                value: _minutes(focusMinutes),
                icon: Icons.timer_outlined,
                tint: const Color(0xFFFFF1D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MiniInsight(
          icon: Icons.pending_actions_rounded,
          label: 'Open tasks',
          value: '$openTasks remaining',
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Focus this week',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minutes logged by day',
                  style: TextStyle(
                    color: _ink.withValues(alpha: .6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 22),
                _WeekBars(values: byDay, weekStart: weekStart),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _showFocusDialog(context, state),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Log a focus session'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        const SizedBox(height: 12),
        const _SoftNote(
          icon: Icons.insights_outlined,
          title: 'Your history stays on this device',
          message:
              'Completed tasks and focus sessions build your weekly progress summary.',
        ),
      ],
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: _ink.withValues(alpha: .63)),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: _ink.withValues(alpha: .58)),
      ),
    ],
  );
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _SectionHeading(title: title, subtitle: subtitle),
      ),
      const SizedBox(width: 8),
      FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(buttonLabel),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _green, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: _ink.withValues(alpha: .62)),
          ),
        ],
      ),
    ),
  );
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: _green),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: _ink.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    this.onToggleReminder,
    this.showDate = false,
    this.overdue = false,
    this.onDelete,
  });
  final HubTask task;
  final VoidCallback onToggle;
  final VoidCallback? onToggleReminder;
  final bool showDate;
  final bool overdue;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (task.subject.trim().isNotEmpty) task.subject,
      if (showDate || overdue) _shortDate(task.dueDate),
      if (overdue) 'Past due',
    ].join('  ·  ');
    final priority = task.priority == 2
        ? 'High'
        : task.priority == 0
        ? 'Low'
        : 'Normal';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 7, 10, 7),
        child: Row(
          children: [
            Checkbox(
              value: task.isDone,
              onChanged: (_) => onToggle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      style: TextStyle(
                        fontSize: 12,
                        color: overdue
                            ? const Color(0xFFB65342)
                            : _ink.withValues(alpha: .58),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!task.isDone)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: task.priority == 2 ? const Color(0xFFFFE8E2) : _mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: task.priority == 2
                        ? const Color(0xFF9C4436)
                        : _green,
                  ),
                ),
              ),
            if (!task.isDone && onToggleReminder != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: task.reminderEnabled
                    ? 'Turn off reminder'
                    : 'Set reminder',
                onPressed: onToggleReminder,
                icon: Icon(
                  task.reminderEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  size: 19,
                  color: task.reminderEnabled
                      ? _green
                      : _ink.withValues(alpha: .5),
                ),
              ),
            if (onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete task',
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded, size: 19),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.entry, required this.onDelete});
  final ExpenseEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1D8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.receipt_long_outlined, color: _green, size: 20),
      ),
      title: Text(
        entry.title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
      subtitle: Text('${entry.category}  ·  ${_shortDate(entry.date)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _amount(entry.amount),
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          IconButton(
            tooltip: 'Delete expense',
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _PantryTile extends StatelessWidget {
  const _PantryTile({
    required this.entry,
    required this.onDelete,
    this.onToggleReminder,
  });
  final PantryEntry entry;
  final VoidCallback onDelete;
  final VoidCallback? onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final days = _daysBetween(DateTime.now(), entry.expiryDate);
    final status = days < 0
        ? 'Expired'
        : days == 0
        ? 'Expires today'
        : days <= 3
        ? 'Use soon'
        : 'Expires ${_shortDate(entry.expiryDate)}';
    final color = days <= 3 ? const Color(0xFF9C4436) : _green;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: _green,
            size: 20,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        subtitle: Text(
          '${entry.quantity.isEmpty ? 'Quantity not set' : entry.quantity}  ·  $status',
          style: TextStyle(color: color, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (days >= 0 && onToggleReminder != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: entry.reminderEnabled
                    ? 'Turn off reminder'
                    : 'Set reminder',
                onPressed: onToggleReminder,
                icon: Icon(
                  entry.reminderEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  size: 19,
                  color: entry.reminderEnabled
                      ? _green
                      : _ink.withValues(alpha: .5),
                ),
              ),
            IconButton(
              tooltip: 'Delete pantry item',
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _green),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: _ink,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink.withValues(alpha: .6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SoftNote extends StatelessWidget {
  const _SoftNote({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _green, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: _ink.withValues(alpha: .67),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values, required this.weekStart});
  final List<int> values;
  final DateTime weekStart;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = values[index];
          final height = maxValue == 0
              ? 8.0
              : (68 * value / maxValue).clamp(8.0, 68.0);
          final isToday = _sameDay(
            weekStart.add(Duration(days: index)),
            DateTime.now(),
          );
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value == 0 ? '' : '$value',
                  style: const TextStyle(fontSize: 10, color: _ink),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: height,
                  width: 19,
                  decoration: BoxDecoration(
                    color: isToday ? _green : const Color(0xFFBBD5C5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? _green : _ink.withValues(alpha: .58),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

Future<void> _showTaskDialog(BuildContext context, HubState state) async {
  final title = TextEditingController();
  final subject = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var dueDate = _dateOnly(DateTime.now());
  var priority = 1;
  var reminderEnabled = true;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('Add to your planner'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Task or assignment',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject or project (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_outlined,
                      color: _green,
                    ),
                    title: const Text('Due date'),
                    subtitle: Text(_longDate(dueDate)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setLocalState(() => dueDate = _dateOnly(picked));
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: reminderEnabled,
                    onChanged: (value) =>
                        setLocalState(() => reminderEnabled = value ?? false),
                    title: const Text('Remind me'),
                    subtitle: const Text(
                      '9:00 AM on the due date, or shortly after if it has passed today',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Priority',
                      style: TextStyle(
                        color: _ink.withValues(alpha: .65),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Low')),
                      ButtonSegment(value: 1, label: Text('Normal')),
                      ButtonSegment(value: 2, label: Text('High')),
                    ],
                    selected: {priority},
                    onSelectionChanged: (value) =>
                        setLocalState(() => priority = value.first),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Save task'),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    final reminderWasEnabled = await state.addTask(
      title: title.text.trim(),
      subject: subject.text.trim(),
      dueDate: dueDate,
      priority: priority,
      reminderEnabled: reminderEnabled,
    );
    if (reminderEnabled && !reminderWasEnabled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Task saved. Allow notifications in Android settings to receive reminders.',
          ),
        ),
      );
    }
  }
  title.dispose();
  subject.dispose();
}

Future<void> _showExpenseDialog(BuildContext context, HubState state) async {
  final title = TextEditingController();
  final amount = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var category = 'Food';
  const categories = ['Food', 'Transport', 'Study', 'Home', 'Other'];
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('Add an expense'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'What was it?'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Add a description'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    return parsed == null || parsed <= 0
                        ? 'Enter an amount above zero'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setLocalState(() => category = value);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Save expense'),
          ),
        ],
      ),
    ),
  );
  if (saved == true)
    await state.addExpense(
      title: title.text.trim(),
      amount: double.parse(amount.text.replaceAll(',', '.')),
      category: category,
    );
  title.dispose();
  amount.dispose();
}

Future<void> _showPantryDialog(BuildContext context, HubState state) async {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var expiry = _dateOnly(DateTime.now().add(const Duration(days: 7)));
  var reminderEnabled = true;
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocalState) => AlertDialog(
        title: const Text('Add a pantry item'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Item name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add an item name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantity,
                    decoration: const InputDecoration(
                      labelText: 'Quantity (optional)',
                      hintText: 'e.g. 2 packs',
                    ),
                  ),
                  const SizedBox(height: 6),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined, color: _green),
                    title: const Text('Expiry date'),
                    subtitle: Text(_longDate(expiry)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: expiry,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null)
                        setLocalState(() => expiry = _dateOnly(picked));
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: reminderEnabled,
                    onChanged: (value) =>
                        setLocalState(() => reminderEnabled = value ?? false),
                    title: const Text('Remind me'),
                    subtitle: const Text(
                      '9:00 AM up to three days before expiry, or shortly after if it has passed today',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate())
                Navigator.pop(dialogContext, true);
            },
            child: const Text('Save item'),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    final reminderWasEnabled = await state.addPantryItem(
      name: name.text.trim(),
      quantity: quantity.text.trim(),
      expiryDate: expiry,
      reminderEnabled: reminderEnabled,
    );
    if (reminderEnabled && !reminderWasEnabled && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item saved. Allow notifications in Android settings to receive reminders.',
          ),
        ),
      );
    }
  }
  name.dispose();
  quantity.dispose();
}

Future<void> _toggleTaskReminder(
  BuildContext context,
  HubState state,
  HubTask task,
) async {
  final changed = await state.toggleTaskReminder(task);
  if (!changed && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder not enabled. Allow notifications in Android settings to use reminders.',
        ),
      ),
    );
  }
}

Future<void> _togglePantryReminder(
  BuildContext context,
  HubState state,
  PantryEntry item,
) async {
  final changed = await state.togglePantryReminder(item);
  if (!changed && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder not enabled. Allow notifications in Android settings to use reminders.',
        ),
      ),
    );
  }
}

Future<void> _showFocusDialog(BuildContext context, HubState state) async {
  final minutes = TextEditingController(text: '25');
  final formKey = GlobalKey<FormState>();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log focus time'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: minutes,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Minutes',
            suffixText: 'min',
          ),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            return parsed == null || parsed < 1 || parsed > 600
                ? 'Enter 1 to 600 minutes'
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate())
              Navigator.pop(dialogContext, true);
          },
          child: const Text('Log session'),
        ),
      ],
    ),
  );
  if (saved == true) await state.addFocusSession(int.parse(minutes.text));
  minutes.dispose();
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
int _daysBetween(DateTime from, DateTime to) =>
    _dateOnly(to).difference(_dateOnly(from)).inDays;
DateTime _mondayOf(DateTime date) =>
    _dateOnly(date).subtract(Duration(days: date.weekday - 1));

String _longDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';
String _shortDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';
String _amount(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2);
String _minutes(int value) {
  if (value < 60) return '$value min';
  final remainder = value % 60;
  return remainder == 0
      ? '${value ~/ 60} h'
      : '${value ~/ 60} h $remainder min';
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
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
