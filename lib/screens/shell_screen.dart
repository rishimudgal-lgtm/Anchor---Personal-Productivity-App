import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../hub_state.dart';
import '../widgets/dialogs.dart';
import 'manage_screen.dart';
import 'progress_screen.dart';
import 'today_screen.dart';
import 'upcoming_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.state});

  final HubState state;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;
  int _manageInitialTab = 0;
  late final PageController _pageController;
  final GlobalKey<ManageScreenState> _manageKey =
      GlobalKey<ManageScreenState>();

  final List<Map<String, Object>> _tabs = const [
    {
      'label': 'Today',
      'icon': Icons.wb_sunny_outlined,
      'selectedIcon': Icons.wb_sunny_rounded,
    },
    {
      'label': 'Upcoming',
      'icon': Icons.upcoming_outlined,
      'selectedIcon': Icons.upcoming_rounded,
    },
    {
      'label': 'Manage',
      'icon': Icons.dashboard_outlined,
      'selectedIcon': Icons.dashboard_rounded,
    },
    {
      'label': 'Progress',
      'icon': Icons.insights_outlined,
      'selectedIcon': Icons.insights_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _openManageTab(int tab) {
    _manageInitialTab = tab;
    _manageKey.currentState?.openTab(tab);
    _onTabSelected(2);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) => Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  TodayScreen(
                    state: widget.state,
                    onOpenManageTab: _openManageTab,
                  ),
                  UpcomingScreen(state: widget.state),
                  ManageScreen(
                    key: _manageKey,
                    state: widget.state,
                    initialTab: _manageInitialTab,
                  ),
                  ProgressScreen(state: widget.state),
                ],
              ),
            ),
          ),
        ),

        // Floating Glassmorphic Navigation Dock
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: isDark
                      ? AppTheme.cardDark
                      : Colors.white.withValues(alpha: 0.97),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.borderGlassDark
                        : AppTheme.borderGlassLight,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_tabs.length + 1, (slot) {
                    if (slot == 2) {
                      return Expanded(
                        child: Semantics(
                          button: true,
                          label: 'Quick Add',
                          child: GestureDetector(
                            onTap: () => showQuickAddSheet(
                              context,
                              widget.state,
                              onOpenTimer: () => _onTabSelected(3),
                              onOpenHabits: () => _openManageTab(4),
                            ),
                            behavior: HitTestBehavior.opaque,
                            child: Tooltip(
                              message: 'Quick Add',
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.skyGradient,
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      size: 23,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
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
                      );
                    }
                    final index = slot > 2 ? slot - 1 : slot;
                    final tab = _tabs[index];
                    final isSelected = _currentIndex == index;
                    final label = tab['label'] as String;
                    final icon = tab['icon'] as IconData;
                    final selectedIcon = tab['selectedIcon'] as IconData;

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: '$label tab',
                        child: GestureDetector(
                          onTap: () => _onTabSelected(index),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? AppTheme.primary.withValues(
                                            alpha: 0.22,
                                          )
                                        : AppTheme.iceBlue)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? selectedIcon : icon,
                                  color: isSelected
                                      ? (isDark
                                            ? AppTheme.primaryLight
                                            : AppTheme.primary)
                                      : (isDark
                                            ? AppTheme.inkMutedDark
                                            : AppTheme.inkMutedLight),
                                  size: 22,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark
                                              ? AppTheme.primaryLight
                                              : AppTheme.primary)
                                        : (isDark
                                              ? AppTheme.inkMutedDark
                                              : AppTheme.inkMutedLight),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
