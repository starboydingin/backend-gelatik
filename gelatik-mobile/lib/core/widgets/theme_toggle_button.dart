import 'package:flutter/material.dart';

/// Dark mode is not part of the current Gelatik mobile direction.  Keep this
/// no-op widget temporarily so existing page headers stay source-compatible
/// while no redundant control is shown to users.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
