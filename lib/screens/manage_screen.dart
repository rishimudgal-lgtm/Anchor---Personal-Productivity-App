import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../widgets/animations.dart';
import '../widgets/budget_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/feature_artwork.dart';
import 'habits_screen.dart';
import '../widgets/pantry_card.dart';
import '../widgets/task_card.dart';
import '../widgets/undo_delete.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key, required this.state, this.initialTab = 0});

  final HubState state;
  final int initialTab;

  @override
  ManageScreenState createState() => ManageScreenState();
}

class ManageScreenState extends State<ManageScreen> {
  late int _activeTab;
  String _searchQuery = '';
  int _taskPriorityFilter = -1; // -1: All, 2: High, 1: Normal, 0: Low
  String _expenseCategoryFilter = 'All';
  int _pantryFreshnessFilter = 0; // 0: All, 1: Soon, 2: Safe, 3: Expired

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 4);
  }

  void openTab(int tab) {
    setState(() {
      _activeTab = tab.clamp(0, 4);
      _searchQuery = '';
    });
  }

  int _daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(target.year, target.month, target.day);
    return d.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_activeTab == 4) return HabitsScreen(state: state);

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
                    'Manage Hub',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plan, track routines, and manage everyday essentials',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Segmented Switcher
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: 0,
                          label: Text('Planner'),
                          icon: Icon(
                            Icons.checklist_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Expenses'),
                          icon: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: AppTheme.amber,
                          ),
                        ),
                        ButtonSegment(
                          value: 2,
                          label: Text('Pantry'),
                          icon: Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: AppTheme.violet,
                          ),
                        ),
                        ButtonSegment(
                          value: 3,
                          label: Text('Shopping'),
                          icon: Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                            color: AppTheme.emerald,
                          ),
                        ),
                        ButtonSegment(
                          value: 4,
                          label: Text('Habits'),
                          icon: Icon(
                            Icons.track_changes_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                      selected: {_activeTab},
                      onSelectionChanged: (val) {
                        setState(() {
                          _activeTab = val.first;
                          _searchQuery = '';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: _activeTab == 0
                          ? 'Search assignments & tasks...'
                          : _activeTab == 1
                          ? 'Search expenses or merchants...'
                          : _activeTab == 2
                          ? 'Search pantry items...'
                          : _activeTab == 3
                          ? 'Search shopping list...'
                          : 'Search habits and routines...',
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
                ],
              ),
            ),
          ),

          // TAB 0: PLANNER
          if (_activeTab == 0) ..._buildPlannerSlivers(context, state, isDark),

          // TAB 1: EXPENSES
          if (_activeTab == 1) ..._buildExpenseSlivers(context, state, isDark),

          // TAB 2: PANTRY
          if (_activeTab == 2) ..._buildPantrySlivers(context, state, isDark),

          // TAB 3: SHOPPING LIST
          if (_activeTab == 3) ..._buildShoppingSlivers(context, state, isDark),

          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  // Planner Sub-view
  List<Widget> _buildPlannerSlivers(
    BuildContext context,
    HubState state,
    bool isDark,
  ) {
    var tasks = state.tasks.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      tasks = tasks
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                t.subject.toLowerCase().contains(q) ||
                t.notes.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_taskPriorityFilter != -1) {
      tasks = tasks.where((t) => t.priority == _taskPriorityFilter).toList();
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      label: const Text('All Priority'),
                      selected: _taskPriorityFilter == -1,
                      onSelected: (s) {
                        if (s) setState(() => _taskPriorityFilter = -1);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.priority_high_rounded,
                        size: 16,
                        color: AppTheme.rose,
                      ),
                      label: const Text('High Priority'),
                      selected: _taskPriorityFilter == 2,
                      onSelected: (s) {
                        if (s) setState(() => _taskPriorityFilter = 2);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.circle_rounded,
                        size: 11,
                        color: AppTheme.primary,
                      ),
                      label: const Text('Normal'),
                      selected: _taskPriorityFilter == 1,
                      onSelected: (s) {
                        if (s) setState(() => _taskPriorityFilter = 1);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.south_rounded,
                        size: 16,
                        color: AppTheme.emerald,
                      ),
                      label: const Text('Low'),
                      selected: _taskPriorityFilter == 0,
                      onSelected: (s) {
                        if (s) setState(() => _taskPriorityFilter = 0);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showTaskDialog(context, state),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (tasks.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: EmptyState(
              icon: Icons.checklist_rounded,
              artworkColor: AppTheme.primary,
              title: _searchQuery.isNotEmpty
                  ? 'No tasks matched'
                  : 'Your planner is empty',
              message: _searchQuery.isNotEmpty
                  ? 'Try a different search word or clear the filter.'
                  : 'Add assignments, projects, or study goals.',
              actionLabel: 'Add Assignment',
              onAction: () => showTaskDialog(context, state),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final task = tasks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideTransition(
                  delay: Duration(milliseconds: 25 * index),
                  child: TaskCard(
                    task: task,
                    showDate: true,
                    onToggle: () => state.toggleTask(task),
                    onTap: () =>
                        showTaskDialog(context, state, existingTask: task),
                    onDelete: () => deleteTaskWithUndo(context, state, task),
                    onToggleReminder: () => state.toggleTaskReminder(task),
                  ),
                ),
              );
            }, childCount: tasks.length),
          ),
        ),
    ];
  }

  // Expense Sub-view
  List<Widget> _buildExpenseSlivers(
    BuildContext context,
    HubState state,
    bool isDark,
  ) {
    var expenses = state.expenses.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      expenses = expenses
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.category.toLowerCase().contains(q) ||
                e.notes.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_expenseCategoryFilter != 'All') {
      expenses = expenses
          .where((e) => e.category == _expenseCategoryFilter)
          .toList();
    }

    const categories = [
      'All',
      'Food',
      'Transport',
      'Study',
      'Groceries',
      'Home',
      'Entertainment',
      'Shopping',
      'Health',
      'Other',
    ];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: BudgetCard(
            state: state,
            onEditBudget: () => showBudgetDialog(context, state),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSel = _expenseCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(
                          ExpenseCard.categoryDetails(cat, isDark)['icon']
                              as IconData,
                          size: 15,
                          color:
                              ExpenseCard.categoryDetails(cat, isDark)['color']
                                  as Color,
                        ),
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (s) {
                          if (s) setState(() => _expenseCategoryFilter = cat);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${expenses.length} record${expenses.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showExpenseDialog(context, state),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Log Expense'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (expenses.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: EmptyState(
              icon: Icons.receipt_long_rounded,
              title: _searchQuery.isNotEmpty
                  ? 'No expenses found'
                  : 'No expenses recorded',
              message: _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords.'
                  : 'Record purchases to monitor your monthly budget.',
              actionLabel: 'Log Expense',
              onAction: () => showExpenseDialog(context, state),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = expenses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideTransition(
                  delay: Duration(milliseconds: 25 * index),
                  child: ExpenseCard(
                    entry: entry,
                    currency: state.currency,
                    onTap: () => showExpenseDialog(
                      context,
                      state,
                      existingExpense: entry,
                    ),
                    onDelete: () =>
                        deleteExpenseWithUndo(context, state, entry),
                  ),
                ),
              );
            }, childCount: expenses.length),
          ),
        ),
    ];
  }

  // Pantry Sub-view
  List<Widget> _buildPantrySlivers(
    BuildContext context,
    HubState state,
    bool isDark,
  ) {
    var pantry = state.pantry.toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      pantry = pantry
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q) ||
                p.quantity.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_pantryFreshnessFilter == 1) {
      pantry = pantry.where((p) {
        final d = _daysUntil(p.expiryDate);
        return d >= 0 && d <= 3;
      }).toList();
    } else if (_pantryFreshnessFilter == 2) {
      pantry = pantry.where((p) => _daysUntil(p.expiryDate) > 3).toList();
    } else if (_pantryFreshnessFilter == 3) {
      pantry = pantry.where((p) => _daysUntil(p.expiryDate) < 0).toList();
    }

    final expiredCount = state.pantry
        .where((p) => _daysUntil(p.expiryDate) < 0)
        .length;
    final soonCount = state.pantry.where((p) {
      final d = _daysUntil(p.expiryDate);
      return d >= 0 && d <= 3;
    }).length;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      label: const Text('All Items'),
                      selected: _pantryFreshnessFilter == 0,
                      onSelected: (s) {
                        if (s) setState(() => _pantryFreshnessFilter = 0);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.timelapse_rounded,
                        size: 16,
                        color: AppTheme.amber,
                      ),
                      label: Text('Use Soon ($soonCount)'),
                      selected: _pantryFreshnessFilter == 1,
                      onSelected: (s) {
                        if (s) setState(() => _pantryFreshnessFilter = 1);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppTheme.emerald,
                      ),
                      label: const Text('Safe & Fresh'),
                      selected: _pantryFreshnessFilter == 2,
                      onSelected: (s) {
                        if (s) setState(() => _pantryFreshnessFilter = 2);
                      },
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      avatar: const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppTheme.rose,
                      ),
                      label: Text('Expired ($expiredCount)'),
                      selected: _pantryFreshnessFilter == 3,
                      onSelected: (s) {
                        if (s) setState(() => _pantryFreshnessFilter = 3);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pantry.length} item${pantry.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.inkMutedDark
                          : AppTheme.inkMutedLight,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => showPantryDialog(context, state),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (pantry.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              artworkColor: AppTheme.emerald,
              title: _searchQuery.isNotEmpty
                  ? 'No pantry items found'
                  : 'Pantry is empty',
              message: _searchQuery.isNotEmpty
                  ? 'Try searching with a different item name.'
                  : 'Track perishables to eliminate food waste.',
              actionLabel: 'Add Pantry Item',
              onAction: () => showPantryDialog(context, state),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = pantry[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FadeSlideTransition(
                  delay: Duration(milliseconds: 25 * index),
                  child: PantryCard(
                    entry: entry,
                    onTap: () =>
                        showPantryDialog(context, state, existingPantry: entry),
                    onDelete: () =>
                        deletePantryItemWithUndo(context, state, entry),
                    onConsume: () =>
                        deletePantryItemWithUndo(context, state, entry),
                    onAdjustQuantity: (delta) =>
                        state.adjustPantryQuantity(entry, delta),
                    onToggleReminder: () => state.togglePantryReminder(entry),
                    onAddToShopping: () async {
                      final added = await state.addPantryItemToShopping(entry);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? '${entry.name} added to shopping list'
                                  : '${entry.name} is already on the list',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            }, childCount: pantry.length),
          ),
        ),
    ];
  }

  List<Widget> _buildShoppingSlivers(
    BuildContext context,
    HubState state,
    bool isDark,
  ) {
    var items = state.shopping.toList()
      ..sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query) ||
                item.quantity.toLowerCase().contains(query),
          )
          .toList();
    }
    final unchecked = state.shopping.where((item) => !item.isChecked).length;
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$unchecked item${unchecked == 1 ? '' : 's'} to pick up',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppTheme.inkMutedDark
                        : AppTheme.inkMutedLight,
                  ),
                ),
              ),
              if (state.shopping.any((item) => item.isChecked))
                TextButton(
                  onPressed: () async {
                    final checked = state.shopping
                        .where((item) => item.isChecked)
                        .toList();
                    for (final item in checked) {
                      await state.deleteShoppingItem(item.id);
                    }
                  },
                  child: const Text('Clear checked'),
                ),
              FilledButton.icon(
                onPressed: () => showShoppingItemDialog(context, state),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
      if (items.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: EmptyState(
              icon: Icons.shopping_cart_outlined,
              artworkColor: AppTheme.amber,
              title: _searchQuery.isEmpty
                  ? 'Your list is empty'
                  : 'No matching items',
              message: _searchQuery.isEmpty
                  ? 'Add groceries and essentials here, or restock from your pantry.'
                  : 'Try a different search term.',
              actionLabel: 'Add Shopping Item',
              onAction: () => showShoppingItemDialog(context, state),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = items[index];
              final itemCategory = item.category.toLowerCase();
              final IconData itemIcon;
              final Color itemAccent;
              if (itemCategory.contains('produce') ||
                  itemCategory.contains('fruit') ||
                  itemCategory.contains('vegetable')) {
                itemIcon = Icons.eco_rounded;
                itemAccent = AppTheme.emerald;
              } else if (itemCategory.contains('dairy')) {
                itemIcon = Icons.water_drop_outlined;
                itemAccent = AppTheme.primary;
              } else if (itemCategory.contains('house')) {
                itemIcon = Icons.home_work_outlined;
                itemAccent = AppTheme.violet;
              } else if (itemCategory.contains('food') ||
                  itemCategory.contains('grocery')) {
                itemIcon = Icons.local_grocery_store_rounded;
                itemAccent = AppTheme.coral;
              } else {
                itemIcon = Icons.shopping_cart_rounded;
                itemAccent = AppTheme.amber;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: FadeSlideTransition(
                  delay: Duration(milliseconds: 20 * index),
                  child: GlassCard(
                    borderRadius: BorderRadius.circular(18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        FeatureArtwork(
                          icon: itemIcon,
                          color: itemAccent,
                          size: 36,
                        ),
                        const SizedBox(width: 5),
                        Checkbox(
                          value: item.isChecked,
                          semanticLabel: item.isChecked
                              ? 'Unmark ${item.name} as purchased'
                              : 'Mark ${item.name} as purchased',
                          onChanged: (_) => state.toggleShoppingItem(item),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => showShoppingItemDialog(
                              context,
                              state,
                              existingItem: item,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      decoration: item.isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: item.isChecked
                                          ? (isDark
                                                ? AppTheme.inkMutedDark
                                                : AppTheme.inkMutedLight)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [item.quantity, item.category]
                                        .where(
                                          (value) => value.trim().isNotEmpty,
                                        )
                                        .join(' · '),
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
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete shopping item',
                          onPressed: () =>
                              deleteShoppingItemWithUndo(context, state, item),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }, childCount: items.length),
          ),
        ),
    ];
  }
}
