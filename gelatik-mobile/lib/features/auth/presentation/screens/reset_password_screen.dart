import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/auth_repository.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String resetToken;
  const ResetPasswordScreen({super.key, required this.resetToken});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text.length < 8 ||
        _passwordController.text != _confirmationController.text) {
      setState(
        () => _error =
            'Gunakan password minimal 8 karakter dan pastikan konfirmasinya sama.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await ref
          .read(authRepositoryProvider)
          .resetPassword(
            resetToken: widget.resetToken,
            password: _passwordController.text,
            passwordConfirmation: _confirmationController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(title: 'Reset Password', showBack: true),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              children: [
                AppTextField(
                  labelText: 'Password baru',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  labelText: 'Konfirmasi password baru',
                  controller: _confirmationController,
                  obscureText: true,
                  errorText: _error,
                ),
                const SizedBox(height: 22),
                AppButton(
                  text: 'Simpan password baru',
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
