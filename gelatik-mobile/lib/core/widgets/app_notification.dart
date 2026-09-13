import 'dart:async';
import 'package:flutter/material.dart';

enum AppNotificationTone { info, success, warning, error }

/// AppNotification — Sistem Notifikasi / Toast / Banner Terpusat di Bagian ATAS Layar.
/// Menjamin seluruh notifikasi muncul di bagian atas (TOP) layar,
/// menghormati Safe Area (status bar, notch) dan tidak pernah muncul di bawah.
class AppNotification {
  AppNotification._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, tone: AppNotificationTone.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, tone: AppNotificationTone.error);
  }

  static void showWarning(BuildContext context, String message) {
    show(context, message: message, tone: AppNotificationTone.warning);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message: message, tone: AppNotificationTone.info);
  }

  /// Menampilkan notifikasi global tanpa memerlukan BuildContext lokal.
  static void showGlobal({
    required String message,
    AppNotificationTone tone = AppNotificationTone.info,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      show(context, message: message, tone: tone, duration: duration);
    }
  }

  /// Menampilkan notifikasi banner di bagian atas layar dengan animasi slide & fade.
  static void show(
    BuildContext context, {
    required String message,
    AppNotificationTone tone = AppNotificationTone.info,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context) ??
        navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopNotificationWidget(
        message: message,
        tone: tone,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final AppNotificationTone tone;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _timer = Timer(widget.duration, _dismissWithAnimation);
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8.0;

    final (Color bgColor, Color borderColor, Color iconColor, IconData icon) =
        switch (widget.tone) {
      AppNotificationTone.success => (
        const Color(0xFFF0FDF4),
        const Color(0xFF86EFAC),
        const Color(0xFF15803D),
        Icons.check_circle_rounded,
      ),
      AppNotificationTone.error => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFCA5A5),
        const Color(0xFFB91C1C),
        Icons.error_rounded,
      ),
      AppNotificationTone.warning => (
        const Color(0xFFFFFBEB),
        const Color(0xFFFCD34D),
        const Color(0xFFB45309),
        Icons.warning_amber_rounded,
      ),
      AppNotificationTone.info => (
        const Color(0xFFF0F9FF),
        const Color(0xFF7DD3FC),
        const Color(0xFF0369A1),
        Icons.info_rounded,
      ),
    };

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismissWithAnimation,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
