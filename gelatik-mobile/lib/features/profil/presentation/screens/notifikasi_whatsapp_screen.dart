import 'package:flutter/material.dart';

import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../widgets/whatsapp_settings_card.dart';

class NotifikasiWhatsAppScreen extends StatelessWidget {
  const NotifikasiWhatsAppScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(
      title: 'Notifikasi WhatsApp',
      showBack: true,
      actions: [ThemeToggleButton(), SizedBox(width: 8)],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: const WhatsAppSettingsCard(popAfterSave: true),
          ),
        ),
      ),
    ),
  );
}
