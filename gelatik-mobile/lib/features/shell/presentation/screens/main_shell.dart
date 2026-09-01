import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chatbot/presentation/screens/chatbot_native_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profil/presentation/screens/profil_screen.dart';
import '../../../services/presentation/screens/services_screen.dart';

/// Persistent application shell for the four primary destinations.
///
/// Feature/detail screens still use Navigator routes, while switching primary
/// destinations no longer creates duplicate pages or loses each tab's state.
class MainShell extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _currentIndex = widget.initialIndex;
  final Map<int, Widget> _tabCache = {};

  Widget _buildTab(int index, bool canAccessAdmin) => switch (index) {
    0 => const HomeScreen(embedded: true),
    1 => const ServicesScreen(embedded: true),
    2 => const NotificationsScreen(embedded: true),
    3 => const ProfilScreen(embedded: true),
    4 when canAccessAdmin => const AdminDashboardScreen(),
    _ => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).currentUser?.role.toLowerCase() ?? '';
    final canAccessAdmin = const {'admin', 'superadmin', 'bkd'}.contains(role);
    final tabCount = canAccessAdmin ? 5 : 4;
    final safeIndex = _currentIndex.clamp(0, tabCount - 1);
    _tabCache.putIfAbsent(
      safeIndex,
      () => _buildTab(safeIndex, canAccessAdmin),
    );

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: List.generate(
          tabCount,
          (index) => _tabCache[index] ?? const SizedBox.shrink(),
        ),
      ),
      floatingActionButton: safeIndex == 0
          ? FloatingActionButton(
              key: const Key('home-chatbot-button'),
              tooltip: 'Buka Asisten Gelatik',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ChatbotNativeScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.accentNavy(context),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: Badge(
                smallSize: 10,
                backgroundColor: AppColors.accentGold(context),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: AppBottomNav(
        currentIndex: safeIndex,
        isAdmin: canAccessAdmin,
        onTap: (index) {
          if (index == safeIndex) return;
          setState(() {
            _currentIndex = index;
            _tabCache.putIfAbsent(
              index,
              () => _buildTab(index, canAccessAdmin),
            );
          });
        },
      ),
    );
  }
}
