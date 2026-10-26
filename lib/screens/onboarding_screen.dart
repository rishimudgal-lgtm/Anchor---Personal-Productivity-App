import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/feature_artwork.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_IntroPage>[
    _IntroPage(
      title: 'Make room for what matters',
      message:
          'Plan assignments and everyday tasks, then see what deserves your attention today.',
      icon: Icons.view_day_rounded,
      accent: AppTheme.primary,
    ),
    _IntroPage(
      title: 'Build routines that stick',
      message:
          'Create habits for any day of the week, or break a routine into small steps you can check off.',
      icon: Icons.checklist_rounded,
      accent: AppTheme.violet,
    ),
    _IntroPage(
      title: 'See your progress clearly',
      message:
          'Track focus, spending, pantry items, and streaks from one calm workspace.',
      icon: Icons.insights_rounded,
      accent: AppTheme.emerald,
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onComplete();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
      return;
    }
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.animateToPage(
      _page + 1,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_page == 0) return;
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _controller.animateToPage(
      _page - 1,
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _pages[_page];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const BrandMark(size: 42),
                      const SizedBox(width: 10),
                      const Text(
                        'Anchor Hub',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _saving ? null : _finish,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      label:
                          'Page ${_page + 1} of ${_pages.length}. ${current.title}. ${current.message}',
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (page) => setState(() => _page = page),
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FeatureArtwork(
                                  icon: page.icon,
                                  color: page.accent,
                                  size: 104,
                                ),
                                const SizedBox(height: 34),
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.7,
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  page.message,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        height: 1.55,
                                        color: isDark
                                            ? AppTheme.inkMutedDark
                                            : AppTheme.inkMutedLight,
                                      ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Semantics(
                    label: 'Onboarding page ${_page + 1} of ${_pages.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final selected = index == _page;
                        return AnimatedContainer(
                          duration:
                              MediaQuery.maybeOf(context)?.disableAnimations ??
                                  false
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: selected ? 26 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : (isDark
                                      ? AppTheme.borderDark
                                      : AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (_page > 0) ...[
                        TextButton.icon(
                          onPressed: _saving ? null : _previous,
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _saving ? null : _next,
                            child: _saving
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _page == _pages.length - 1
                                        ? 'Get started'
                                        : 'Continue',
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
}
