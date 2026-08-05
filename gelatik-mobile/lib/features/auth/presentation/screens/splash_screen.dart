import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../core/theme/app_colors.dart';

/// SplashScreen — Layar Awal Aplikasi Gelatik Mobile (BAGIAN 1)
/// Mengikuti spesifikasi desain resmi: Logo Gelatik, Wordmark GELATIK (primaryTeal),
/// Tagline "Gerbang Layanan TIK", loading indicator, dan motif Siger halus di latar bawah.
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
    // Pengecekan token tersimpan (simulasi ~2 detik)
    final isLoggedIn = await ref.read(authProvider.notifier).checkAuthToken();

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
          // -------------------------------------------------------------------
          // Motif Siger Dekoratif Halus di Bagian Bawah (Asset Lokal, Opacity Rendah)
          // -------------------------------------------------------------------
          Positioned(
            bottom: -20,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: isDark ? 0.15 : 0.22,
                child: Image.asset(
                  'assets/images/SIGER.png',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'images/SIGER.png',
                      height: 200,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Konten Utama di Tengah
          // -------------------------------------------------------------------
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 4),

                    // Logo Burung Gelatik Resmi
                    Image.asset(
                      'assets/images/logo-nobackground&teksgelatik.png',
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'images/logo-nobackground&teksgelatik.png',
                          height: 150,
                          fit: BoxFit.contain,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Wordmark GELATIK (Primary Teal)
                    Text(
                      'GELATIK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: primaryTeal,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Gerbang Layanan TIK',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const Spacer(flex: 5),

                    // ---------------------------------------------------------
                    // Loading Indicator & Status Memuat
                    // ---------------------------------------------------------
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: primaryTeal.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(actionEmerald),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MEMUAT SISTEM...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: mutedText,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
