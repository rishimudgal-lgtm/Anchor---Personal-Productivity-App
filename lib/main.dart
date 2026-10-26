import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'hub_state.dart';
import 'reminder_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = ReminderService.instance;
  runApp(
    MyManagementHub(
      state: HubState(reminders: reminders),
      reminders: reminders,
    ),
  );
}

class MyManagementHub extends StatefulWidget {
  const MyManagementHub({
    super.key,
    required this.state,
    required this.reminders,
  });

  final HubState state;
  final ReminderService reminders;

  @override
  State<MyManagementHub> createState() => _MyManagementHubState();
}

class _MyManagementHubState extends State<MyManagementHub> {
  bool _loading = true;
  Object? _storageError;
  Object? _reminderError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _loading = true;
      _storageError = null;
    });
    Object? reminderError;
    try {
      await widget.reminders.initialize();
    } catch (error) {
      reminderError = error;
    }

    Object? storageError;
    try {
      await widget.state.load();
    } catch (error) {
      storageError = error;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _storageError = storageError;
      _reminderError = reminderError;
    });
  }

  Future<void> _retryReminders() async {
    try {
      await widget.reminders.initialize();
      if (mounted) setState(() => _reminderError = null);
    } catch (error) {
      if (mounted) setState(() => _reminderError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => MaterialApp(
        title: 'Anchor Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: widget.state.themeMode,
        home: _home(),
      ),
    );
  }

  Widget _home() {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Anchor Hub…'),
            ],
          ),
        ),
      );
    }
    if (_storageError != null) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_rounded, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Anchor Hub could not load your saved data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check available storage, then try again. Your saved information has not been intentionally cleared.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _initialize,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!widget.state.settings.hasCompletedOnboarding) {
      return OnboardingScreen(onComplete: widget.state.completeOnboarding);
    }

    return Column(
      children: [
        if (_reminderError != null)
          MaterialBanner(
            content: const Text(
              'Local reminders could not start. The rest of the app is ready.',
            ),
            leading: const Icon(Icons.notifications_off_outlined),
            actions: [
              TextButton(
                onPressed: _retryReminders,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => setState(() => _reminderError = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        Expanded(child: ShellScreen(state: widget.state)),
      ],
    );
  }
}
