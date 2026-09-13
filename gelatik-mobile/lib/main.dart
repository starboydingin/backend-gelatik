import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/realtime/realtime_coordinator.dart';
import 'core/realtime/realtime_event.dart';
import 'core/realtime/realtime_socket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_notification.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
    // One durable `notification` event is emitted for each inbox update.
    // Business events still refresh feature data, but must not duplicate this
    // visible feedback on the user device.
    // Read-state sync is intentionally silent. It still refreshes the badge
    // through its own listener, but must not look like a new notification.
    if (!mounted ||
        event.type != 'notification' ||
        event.status == 'read' ||
        event.status == 'read_all' ||
        message == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppNotification.showGlobal(
        message: message,
        tone: AppNotificationTone.info,
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
    return MaterialApp(
      title: 'Gelatik Mobile',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNotification.navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
