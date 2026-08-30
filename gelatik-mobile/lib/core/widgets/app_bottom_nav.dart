import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Main navigation defined by DESIGN.md. Admin is a role-aware fifth tab.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAdmin;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final items = [
      const _NavItem(label: 'Beranda', icon: Icons.home_outlined),
      const _NavItem(label: 'Layanan', icon: Icons.grid_view_outlined),
      const _NavItem(label: 'Notifikasi', icon: Icons.notifications_outlined),
      const _NavItem(label: 'Profil', icon: Icons.person_outline_rounded),
      if (isAdmin)
        const _NavItem(
          label: 'Admin',
          icon: Icons.admin_panel_settings_rounded,
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset > 0 ? 0 : 10),
      child: Container(
        height: 74 + bottomInset,
        decoration: BoxDecoration(
          color: AppColors.colorPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: AppColors.colorPrimaryDark),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260F172A),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final isSelected = index == currentIndex;
                    final color = isSelected
                        ? AppColors.colorTextPrimary
                        : AppColors.onPrimaryLight.withValues(alpha: .78);

                    return Expanded(
                      child: InkWell(
                        onTap: () => onTap(index),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.colorAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.icon, color: color, size: 22),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: color,
                                ),
                              ),
                            ],
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

class _NavItem {
  final String label;
  final IconData icon;

  const _NavItem({required this.label, required this.icon});
}
