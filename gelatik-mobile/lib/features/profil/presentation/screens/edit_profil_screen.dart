import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../auth/providers/auth_provider.dart';

class EditProfilScreen extends ConsumerStatefulWidget {
  const EditProfilScreen({super.key});

  @override
  ConsumerState<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends ConsumerState<EditProfilScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _opdController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _opdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        !_emailController.text.trim().contains('@')) {
      AppNotification.showWarning(context, 'Nama dan email valid wajib diisi.');
      return;
    }
    final ok = await ref
        .read(authProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          noHp: _phoneController.text.trim(),
          namaOpd: _opdController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      AppNotification.showSuccess(context, 'Profil berhasil diperbarui.');
      Navigator.of(context).pop();
      return;
    }
    AppNotification.showError(
      context,
      ref.read(authProvider).errorMessage ??
          'Profil tidak dapat diperbarui.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    if (!_initialized) {
      _initialized = true;
      _nameController.text = user?.name ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = user?.noHp ?? '';
      _opdController.text = user?.namaOpd ?? '';
    }
    return Scaffold(
      appBar: const GelatikPageHeader(title: 'Edit Profil', showBack: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    labelText: 'Nama lengkap',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    labelText: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    labelText: 'Nomor WhatsApp / HP',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    labelText: 'Nama OPD',
                    controller: _opdController,
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: 'Simpan Perubahan',
                    backgroundColor: AppColors.actionEmerald(context),
                    isLoading: auth.isLoading,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
