import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/home_screen.dart';
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
        builder: (_) => isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            bottom: -28,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: isDark ? 0.13 : 0.18,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = math.max(
                      220.0,
                      math.min(constraints.maxWidth * 0.72, 320.0),
                    );
                    return Image.asset(
                      'assets/images/SIGER.png',
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

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                            style: AuthTypography.brandTitle(
                              context,
                              fontSize: 14,
                            ).copyWith(color: primaryTeal, letterSpacing: 1.8),
                          ),
                          const SizedBox(height: 54),
                          SizedBox(
                            width: 140,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                backgroundColor: primaryTeal.withValues(
                                  alpha: 0.15,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  actionEmerald,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'MEMUAT SISTEM...',
                            style: AuthTypography.brandTitle(
                              context,
                              fontSize: 11,
                            ).copyWith(color: mutedText, letterSpacing: 2),
                          ),
                        ],
                      ),
                    ),
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
