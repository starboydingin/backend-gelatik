import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shell/presentation/screens/main_shell.dart';
import '../../providers/auth_provider.dart';
import '../theme/auth_typography.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndNavigate();
    });
  }

  Future<void> _checkTokenAndNavigate() async {
    final isLoggedIn = await ref.read(authProvider.notifier).checkAuthToken();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBackground,
      body: Stack(
        children: [
          Positioned(
            bottom: -28,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.06,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.max(
                      220.0,
                      math.min(constraints.maxWidth * 0.72, 320.0),
                    );
                    return Image.asset(
                      'assets/images/icon lampung.png',
                      width: width,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final logoWidth = math.max(
                  190.0,
                  math.min(constraints.maxWidth * 0.62, 240.0),
                );
                final contentWidth = math.min(constraints.maxWidth, 420.0);

                return SizedBox(
                  height: constraints.maxHeight,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: SizedBox(
                              width: contentWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo-tanpabackground.png',
                                      key: const Key('splash_gelatik_logo'),
                                      width: logoWidth,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'GERBANG LAYANAN TIK',
                                      textAlign: TextAlign.center,
                                      style:
                                          AuthTypography.brandTitle(
                                            context,
                                            fontSize: 14,
                                          ).copyWith(
                                            color: AppColors.colorPrimary,
                                            letterSpacing: 1.8,
                                          ),
                                    ),
                                    SizedBox(
                                      height: (constraints.maxHeight * 0.09).clamp(
                                        28.0,
                                        54.0,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 140,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          minHeight: 4,
                                          backgroundColor: AppColors.colorBorder,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.colorAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'MEMUAT SISTEM...',
                                      style:
                                          AuthTypography.brandTitle(
                                            context,
                                            fontSize: 11,
                                          ).copyWith(
                                            color: AppColors.colorTextMuted,
                                            letterSpacing: 2,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text(
                          '© ${DateTime.now().year} Diskominfotik Provinsi Lampung',
                          key: const Key('splash_copyright_text'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.colorTextMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
