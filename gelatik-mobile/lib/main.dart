import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/realtime/realtime_coordinator.dart';
import 'core/realtime/realtime_event.dart';
import 'core/realtime/realtime_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: GelatikApp()));
}

class GelatikApp extends ConsumerStatefulWidget {
  const GelatikApp({super.key});

  @override
  ConsumerState<GelatikApp> createState() => _GelatikAppState();
}

class _GelatikAppState extends ConsumerState<GelatikApp>
    with WidgetsBindingObserver {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _realtimeSubscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .listen(_showRealtimeFeedback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(realtimeSocketServiceProvider).handleLifecycle(state);
  }

  void _showRealtimeFeedback(RealtimeEvent event) {
    final message = event.message;
    if (!mounted || message == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = _scaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(realtimeCoordinatorProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gelatik Mobile',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
