import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/pending_activation_banner.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../theme/auth_typography.dart';

/// LoginScreen — Layar Utama Autentikasi (BAGIAN 2 & FR-35 Compliance)
/// Menggunakan Design Tokens resmi (primaryTeal, actionEmerald, accentNavy, accentGold).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _identifierError;
  String? _passwordError;
  String? _generalError;
  bool _showPendingBanner = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (ref.read(authProvider).isLoading) return;

    // Reset state error
    setState(() {
      _identifierError = null;
      _passwordError = null;
      _generalError = null;
      _showPendingBanner = false;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    bool isValid = true;
    if (identifier.isEmpty) {
      setState(() => _identifierError = 'Email atau NIP tidak boleh kosong');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password tidak boleh kosong');
      isValid = false;
    }

    if (!isValid) return;

    // Panggil AuthNotifier Riverpod
    final authNotifier = ref.read(authProvider.notifier);
    final result = await authNotifier.login(identifier, password);

    if (!mounted) return;

    if (result == AuthResultStatus.authenticated) {
      // 1. User aktif (status = '1') -> Navigasi ke HomeScreen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (result == AuthResultStatus.pendingActivation) {
      // 2. Response 403 (Akun belum aktif / status = '0') -> Tampilkan PendingActivationBanner & Dialog FR-35
      final authState = ref.read(authProvider);
      final backendMessage =
          authState.pendingActivationMessage ??
          'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.';

      setState(() {
        _showPendingBanner = true;
      });

      // Tampilkan Dialog Peringatan Eksplisit FR-35 dengan pesan PERSIS
      PendingActivationBanner.show(
        context,
        title: 'Akun Tidak Aktif',
        message: backendMessage,
      );
    } else if (result == AuthResultStatus.error) {
      // 3. Error lain (401/422 / Email/Password Salah) -> SnackBar / General Banner
      final authState = ref.read(authProvider);
      final errorMessage =
          authState.errorMessage ?? 'Email/NIP atau password salah.';

      setState(() {
        _generalError = errorMessage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                final minHeight = math.max(
                  0.0,
                  constraints.maxHeight - keyboardInset - 24,
                );
                final logoWidth = math.max(
                  150.0,
                  math.min(constraints.maxWidth * 0.44, 180.0),
                );
                final sigerWidth = math.max(
                  65.0,
                  math.min(constraints.maxWidth * 0.19, 82.0),
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, keyboardInset + 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ---------------------------------------------------------------
                        // Header: Logo Gelatik + Wordmark GELATIK + Subtitle
                        // ---------------------------------------------------------------
                        Image.asset(
                          'assets/images/logo-tanpabackground.png',
                          key: const Key('login_gelatik_logo'),
                          width: logoWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GERBANG LAYANAN TIK',
                          textAlign: TextAlign.center,
                          style: AuthTypography.brandTitle(
                            context,
                            fontSize: 13,
                          ).copyWith(color: mutedText, letterSpacing: 1.4),
                        ),

                        const SizedBox(height: 24),

                        // ---------------------------------------------------------------
                        // Card Form Login (Design Token Compliant)
                        // ---------------------------------------------------------------
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang',
                                  style: AuthTypography.screenHeading(
                                    context,
                                    primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Silakan masuk menggunakan email atau NIP Anda.',
                                  style: AuthTypography.subtitle(
                                    context,
                                    mutedText,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Banner Peringatan Pending Activation (FR-35)
                                if (_showPendingBanner) ...[
                                  PendingActivationBanner(
                                    title: 'Akun Tidak Aktif',
                                    message:
                                        authState.pendingActivationMessage ??
                                        'Akun Anda sedang tidak aktif atau telah dinonaktifkan. Hubungi administrator jika Anda memerlukan bantuan.',
                                    onDismiss: () {
                                      setState(
                                        () => _showPendingBanner = false,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Banner General Error
                                if (_generalError != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: theme
                                              .colorScheme
                                              .onErrorContainer,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _generalError!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Field Email atau NIP
                                AppTextField(
                                  labelText: 'Email atau NIP',
                                  hintText: 'Masukkan email atau NIP Anda',
                                  controller: _identifierController,
                                  keyboardType: TextInputType.text,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  errorText: _identifierError,
                                  onChanged: (_) {
                                    if (_identifierError != null) {
                                      setState(() => _identifierError = null);
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Field Password
                                AppTextField(
                                  labelText: 'Kata Sandi',
                                  hintText: '••••••••',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  errorText: _passwordError,
                                  onChanged: (_) {
                                    if (_passwordError != null) {
                                      setState(() => _passwordError = null);
                                    }
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Tombol Masuk Utama (KHUSUS actionEmerald)
                                AppButton(
                                  text: 'Masuk',
                                  backgroundColor: actionEmerald,
                                  textColor: Colors.white,
                                  isLoading: authState.isLoading,
                                  allowTextWrap: true,
                                  onPressed: _handleLogin,
                                ),

                                const SizedBox(height: 12),

                                // Tombol Daftar Akun Baru (Outlined)
                                AppButton(
                                  text: 'Daftar Akun Baru',
                                  variant: AppButtonVariant.outlined,
                                  textColor: primaryTeal,
                                  allowTextWrap: true,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ---------------------------------------------------------------
                        // Footer: Motif Siger Crown (Asset Lokal)
                        // ---------------------------------------------------------------
                        Opacity(
                          opacity: 0.5,
                          child: Image.asset(
                            'assets/images/SIGER.png',
                            key: const Key('login_siger_logo'),
                            width: sigerWidth,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Floating Theme Toggle Button di Pojok Kanan Atas
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: const ThemeToggleButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
