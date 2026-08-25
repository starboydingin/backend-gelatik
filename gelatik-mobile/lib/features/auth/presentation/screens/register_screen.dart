import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_searchable_select.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../theme/auth_typography.dart';

/// RegisterScreen — Layar Registrasi Akun Baru GELATIK (BAGIAN 3 & FR-36 Compliance)
/// Menggunakan Design Tokens resmi (primaryTeal, actionEmerald, accentNavy, accentGold).
/// Kepatuhan Kontrak API Backend: Nama, NIP (18 digit), Email, No WA, OPD Dropdown, Password, Konfirmasi.
class RegisterScreen extends ConsumerStatefulWidget {
  final WidgetBuilder? homeBuilder;

  const RegisterScreen({super.key, this.homeBuilder});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _selectedOpd;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  // Validation Error Messages
  String? _nameError;
  String? _nipError;
  String? _emailError;
  String? _noHpError;
  String? _opdError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadOpds();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (ref.read(authProvider).isLoading) return;

    setState(() {
      _nameError = null;
      _nipError = null;
      _emailError = null;
      _noHpError = null;
      _opdError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = null;
    });

    final name = _nameController.text.trim();
    final nip = _nipController.text.trim();
    final email = _emailController.text.trim();
    final noHp = _noHpController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    bool isValid = true;

    // 1. Validasi Nama
    if (name.isEmpty) {
      setState(() => _nameError = 'Nama lengkap wajib diisi');
      isValid = false;
    } else if (name.length < 3) {
      setState(() => _nameError = 'Nama minimal 3 karakter');
      isValid = false;
    }

    // 2. Validasi NIP (BAGIAN 3 - Wajib 18 Digit Angka)
    if (nip.isEmpty) {
      setState(() => _nipError = 'NIP wajib diisi');
      isValid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(nip)) {
      setState(() => _nipError = 'NIP hanya boleh berisi angka');
      isValid = false;
    } else if (nip.length != 18) {
      setState(() => _nipError = 'NIP harus 18 digit');
      isValid = false;
    }

    // 3. Validasi Email (BAGIAN 3 - Validasi Format Standar Tanpa Domain Instansi Paksaan)
    if (email.isEmpty) {
      setState(() => _emailError = 'Email wajib diisi');
      isValid = false;
    } else if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(email)) {
      setState(() => _emailError = 'Format email tidak valid');
      isValid = false;
    }

    // 4. Validasi Nomor WhatsApp / HP
    if (noHp.isEmpty) {
      setState(() => _noHpError = 'Nomor WhatsApp wajib diisi');
      isValid = false;
    } else if (!RegExp(r'^\d+$').hasMatch(noHp)) {
      setState(() => _noHpError = 'Nomor WA hanya boleh berisi angka');
      isValid = false;
    } else if (noHp.length < 10 || noHp.length > 15) {
      setState(() => _noHpError = 'Nomor WA harus 10–15 digit');
      isValid = false;
    }

    // 5. Validasi Dropdown OPD
    if (_selectedOpd == null || _selectedOpd!.isEmpty) {
      setState(
        () => _opdError = 'Silakan pilih Organisasi Perangkat Daerah (OPD)',
      );
      isValid = false;
    }

    // 6. Validasi Password
    if (password.isEmpty) {
      setState(() => _passwordError = 'Password wajib diisi');
      isValid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = 'Password minimal 8 karakter');
      isValid = false;
    }

    // 7. Validasi Konfirmasi Password
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Konfirmasi password wajib diisi');
      isValid = false;
    } else if (confirmPassword != password) {
      setState(() => _confirmPasswordError = 'Konfirmasi password tidak cocok');
      isValid = false;
    }

    // 8. Validasi Syarat & Ketentuan
    if (!_agreeTerms) {
      setState(() => _termsError = 'Harap menyetujui syarat dan ketentuan');
      isValid = false;
    }

    if (!isValid) return;

    // Process Registration via AuthNotifier
    final result = await ref
        .read(authProvider.notifier)
        .register(
          name: name,
          nip: nip,
          email: email,
          noHp: noHp,
          namaOpd: _selectedOpd!,
          password: password,
          passwordConfirmation: confirmPassword,
        );

    if (!mounted) return;

    if (result == AuthResultStatus.authenticated) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: widget.homeBuilder ?? (_) => const HomeScreen(),
        ),
        (route) => false,
      );
      return;
    }

    final state = ref.read(authProvider);
    final errors = state.validationErrors;
    setState(() {
      _nameError = errors['name'];
      _nipError = errors['nip'];
      _emailError = errors['email'];
      _noHpError = errors['no_hp'];
      _opdError = errors['nama_opd'];
      _passwordError = errors['password'];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(state.errorMessage ?? 'Registrasi gagal. Coba lagi.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  constraints.maxHeight - keyboardInset - 32,
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
                  padding: EdgeInsets.fromLTRB(20, 16, 20, keyboardInset + 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Header Logo & Subtitle
                        Image.asset(
                          'assets/images/logo-tanpabackground.png',
                          key: const Key('register_gelatik_logo'),
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

                        const SizedBox(height: 20),

                        // Form Card Utama
                        AppCard(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daftar Akun Baru',
                                  style: AuthTypography.screenHeading(
                                    context,
                                    primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lengkapi formulir di bawah ini untuk mendaftar akun.',
                                  style: AuthTypography.subtitle(
                                    context,
                                    mutedText,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // 1. Nama Lengkap
                                AppTextField(
                                  labelText: 'Nama Lengkap',
                                  hintText: 'Masukkan nama lengkap Anda',
                                  controller: _nameController,
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                  errorText: _nameError,
                                  onChanged: (_) {
                                    if (_nameError != null) {
                                      setState(() => _nameError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // 2. NIP (BAGIAN 3 - Pengganti Username)
                                AppTextField(
                                  labelText: 'NIP',
                                  hintText: 'Masukkan 18 digit NIP Anda',
                                  controller: _nipController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  errorText: _nipError,
                                  onChanged: (_) {
                                    if (_nipError != null) {
                                      setState(() => _nipError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // 3. Email (BAGIAN 3 - Label Email saja & Validasi Longgar)
                                AppTextField(
                                  labelText: 'Email',
                                  hintText: 'contoh@email.com',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  errorText: _emailError,
                                  onChanged: (_) {
                                    if (_emailError != null) {
                                      setState(() => _emailError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // 4. Nomor WhatsApp / HP
                                AppTextField(
                                  labelText: 'Nomor WhatsApp',
                                  hintText: '081234567890',
                                  controller: _noHpController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                  ),
                                  errorText: _noHpError,
                                  onChanged: (_) {
                                    if (_noHpError != null) {
                                      setState(() => _noHpError = null);
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),

                                // 5. OPD is a long server-provided list. Use a
                                // searchable picker instead of a clipped native
                                // dropdown, especially on narrow devices.
                                AppSearchableSelect<String>(
                                  key: const Key('opd_dropdown'),
                                  labelText:
                                      'Organisasi Perangkat Daerah (OPD)',
                                  hintText: 'Pilih OPD Anda',
                                  searchHint: 'Cari nama OPD…',
                                  value: _selectedOpd,
                                  errorText: _opdError,
                                  prefixIcon: const Icon(
                                    Icons.business_rounded,
                                  ),
                                  enabled: !authState.isOpdLoading,
                                  options: authState.opds
                                      .map(
                                        (opd) => SearchableSelectOption<String>(
                                          value: opd,
                                          label: opd,
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) => setState(() {
                                    _selectedOpd = value;
                                    _opdError = null;
                                  }),
                                ),
                                if (authState.isOpdLoading) ...[
                                  const SizedBox(height: 8),
                                  const LinearProgressIndicator(
                                    key: Key('opd_loading'),
                                  ),
                                ] else if (authState.opdErrorMessage !=
                                    null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    key: const Key('opd_error'),
                                    children: [
                                      Expanded(
                                        child: Text(
                                          authState.opdErrorMessage!,
                                          style: TextStyle(
                                            color: theme.colorScheme.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        key: const Key('opd_retry'),
                                        onPressed: () => ref
                                            .read(authProvider.notifier)
                                            .loadOpds(),
                                        child: const Text('Coba Lagi'),
                                      ),
                                    ],
                                  ),
                                ] else if (authState.opds.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    key: const Key('opd_empty'),
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Daftar OPD tidak tersedia.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => ref
                                            .read(authProvider.notifier)
                                            .loadOpds(),
                                        child: const Text('Muat Ulang'),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),

                                // 6. Password
                                AppTextField(
                                  labelText: 'Password',
                                  hintText: 'Minimal 8 karakter',
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
                                const SizedBox(height: 16),

                                // 7. Konfirmasi Password
                                AppTextField(
                                  labelText: 'Konfirmasi Password',
                                  hintText: '••••••••',
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  errorText: _confirmPasswordError,
                                  onChanged: (_) {
                                    if (_confirmPasswordError != null) {
                                      setState(
                                        () => _confirmPasswordError = null,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Checkbox Syarat & Ketentuan
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _agreeTerms,
                                        activeColor: actionEmerald,
                                        onChanged: (val) {
                                          setState(() {
                                            _agreeTerms = val ?? false;
                                            if (_agreeTerms) _termsError = null;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _agreeTerms = !_agreeTerms;
                                            if (_agreeTerms) _termsError = null;
                                          });
                                        },
                                        child: Text(
                                          'Saya menyetujui syarat dan ketentuan penggunaan layanan GELATIK.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_termsError != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _termsError!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Tombol Submit Utama (actionEmerald)
                                AppButton(
                                  text: 'Daftar Sekarang',
                                  backgroundColor: actionEmerald,
                                  textColor: Colors.white,
                                  isLoading: authState.isLoading,
                                  allowTextWrap: true,
                                  onPressed: _handleRegister,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Link Ke Login
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: TextStyle(fontSize: 14, color: mutedText),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'Masuk di sini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryTeal,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Footer: Siger Crown Asset
                        Opacity(
                          opacity: 0.5,
                          child: Image.asset(
                            'assets/images/SIGER.png',
                            key: const Key('register_siger_logo'),
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
