import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../auth/repositories/auth_repository.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text;
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;
    if (currentPassword.isEmpty ||
        password.length < 8 ||
        password != passwordConfirmation) {
      setState(() {
        _error = password != passwordConfirmation
            ? 'Konfirmasi password baru belum sama.'
            : 'Isi password lama dan password baru minimal 8 karakter.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(title: 'Ganti Password', showBack: true),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  labelText: 'Password Lama',
                  hintText: 'Masukkan password lama',
                  controller: _currentPasswordController,
                  obscureText: true,
                  errorText: _error,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  labelText: 'Password Baru',
                  hintText: 'Masukkan password baru',
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Gunakan minimal 8 karakter yang mudah Anda ingat.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  labelText: 'Konfirmasi Password Baru',
                  hintText: 'Ulangi password baru',
                  controller: _passwordConfirmationController,
                  obscureText: true,
                  onChanged: (_) => setState(() => _error = null),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Simpan Password',
                  backgroundColor: AppColors.actionEmerald(context),
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
