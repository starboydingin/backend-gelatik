import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/repositories/notification_repository.dart';
import '../realtime/realtime_socket_service.dart';

/// Header notification entry point with a count sourced from the signed-in
/// account. It refreshes when the durable realtime inbox event arrives.
class NotificationBadgeButton extends ConsumerStatefulWidget {
  final int? initialUnread;

  const NotificationBadgeButton({super.key, this.initialUnread});

  @override
  ConsumerState<NotificationBadgeButton> createState() =>
      _NotificationBadgeButtonState();
}

class _NotificationBadgeButtonState
    extends ConsumerState<NotificationBadgeButton> {
  StreamSubscription? _subscription;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _unread = widget.initialUnread ?? 0;
    if (widget.initialUnread == null) Future.microtask(_refreshUnread);
    _subscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where((event) => event.type == 'notification')
        .listen((_) => _refreshUnread());
  }

  @override
  void didUpdateWidget(covariant NotificationBadgeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialUnread != null &&
        widget.initialUnread != oldWidget.initialUnread) {
      _unread = widget.initialUnread!;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final notifications = await ref
          .read(notificationRepositoryProvider)
          .getNotifications();
      if (mounted) {
        setState(
          () => _unread = notifications.where((item) => !item.isRead).length,
        );
      }
    } catch (_) {
      // A failed badge refresh must never block the current screen.
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notifikasi',
    onPressed: () async {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
      await _refreshUnread();
    },
    icon: Badge.count(
      isLabelVisible: _unread > 0,
      count: _unread > 99 ? 99 : _unread,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.onSecondary,
      child: const Icon(Icons.notifications_none_rounded),
    ),
  );
}
