import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Beralih ke Light Mode' : 'Beralih ke Dark Mode',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: isDark ? Colors.amber : Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            isDark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
