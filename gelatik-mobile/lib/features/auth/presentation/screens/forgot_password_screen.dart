import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/auth_repository.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  String? _challengeId;
  bool _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = 'Masukkan email, NIP, atau username akun.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(identifier);
      if (mounted) {
        setState(() {
          _challengeId = challenge['challenge_id']?.toString();
          _message =
              'Kode verifikasi telah dikirim ke nomor WhatsApp terdaftar.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_challengeId == null || _otpController.text.trim().length != 6) {
      setState(() => _error = 'Masukkan kode verifikasi 6 digit.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resetToken = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetOtp(
            challengeId: _challengeId!,
            otp: _otpController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(resetToken: resetToken),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(title: 'Lupa Password', showBack: true),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atur ulang kata sandi',
                  style: TextStyle(
                    color: AppColors.primaryTeal(context),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan email, NIP, atau username. Kode verifikasi akan dikirim melalui WhatsApp.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  labelText: 'Email, NIP, atau username',
                  hintText: 'Identitas akun',
                  controller: _identifierController,
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: _error,
                  onChanged: (_) => setState(() => _error = null),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(_message!, style: const TextStyle(color: Colors.green)),
                ],
                const SizedBox(height: 20),
                AppButton(
                  text: _challengeId == null
                      ? 'Kirim kode WhatsApp'
                      : 'Kirim ulang kode',
                  backgroundColor: AppColors.actionEmerald(context),
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                if (_challengeId != null) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    labelText: 'Kode verifikasi',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    errorText: _error,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Verifikasi kode',
                    backgroundColor: AppColors.primaryTeal(context),
                    isLoading: _loading,
                    onPressed: _verify,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
