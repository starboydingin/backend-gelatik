import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/kritik_saran_provider.dart';

/// KritikSaranScreen — Form Kritik & Saran Pengguna Layanan TIK (M-G)
class KritikSaranScreen extends ConsumerStatefulWidget {
  const KritikSaranScreen({super.key});

  @override
  ConsumerState<KritikSaranScreen> createState() => _KritikSaranScreenState();
}

class _KritikSaranScreenState extends ConsumerState<KritikSaranScreen> {
  final TextEditingController _kritikController = TextEditingController();
  final TextEditingController _saranController = TextEditingController();

  String? _kritikError;
  String? _saranError;

  @override
  void dispose() {
    _kritikController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (ref.read(kritikSaranProvider).isLoading) return;

    setState(() {
      _kritikError = null;
      _saranError = null;
    });

    final kritikText = _kritikController.text.trim();
    final saranText = _saranController.text.trim();

    if (kritikText.isEmpty) {
      setState(() => _kritikError = 'Kritik wajib diisi');
      return;
    }

    if (saranText.isEmpty) {
      setState(() => _saranError = 'Saran wajib diisi');
      return;
    }

    final success = await ref
        .read(kritikSaranProvider.notifier)
        .submitKritikSaran(kritik: kritikText, saran: saranText);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      final message = ref.read(kritikSaranProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Kritik dan saran gagal dikirim.')),
      );
    }
  }

  void _showSuccessDialog() {
    final actionEmerald = AppColors.actionEmerald(context);
    final primaryTeal = AppColors.primaryTeal(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: actionEmerald.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: actionEmerald,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Terima Kasih!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kritik dan saran Anda sangat berharga untuk meningkatkan kualitas pelayanan TIK Pemprov Lampung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(dialogContext).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Tutup & Kembali',
                  backgroundColor: actionEmerald,
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close Dialog
                    Navigator.of(context).pop(); // Back to previous page
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentGold = AppColors.accentGold(context);
    final state = ref.watch(kritikSaranProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kritik & Saran'),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Decorative Icon Container (accentGold background)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.rate_review_rounded,
                        color: accentGold,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Form Kritik & Saran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sampaikan evaluasi & masukan Anda untuk perbaikan sistem.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),

                // Field 1: Kritik Multiline (AppTextField with bold label)
                AppTextField(
                  controller: _kritikController,
                  labelText: 'Kritik Layanan TIK',
                  hintText:
                      'Sampaikan hal-hal yang perlu dievaluasi atau kendala yang ditemui...',
                  maxLines: 4,
                  errorText: _kritikError,
                  prefixIcon: const Icon(Icons.feedback_outlined),
                ),

                const SizedBox(height: 16),

                // Field 2: Saran Multiline (AppTextField with bold label)
                AppTextField(
                  controller: _saranController,
                  labelText: 'Saran & Masukan Perbaikan',
                  hintText:
                      'Sampaikan saran konstruktif untuk pengembangan aplikasi/layanan ke depan...',
                  maxLines: 4,
                  errorText: _saranError,
                  prefixIcon: const Icon(Icons.lightbulb_outline_rounded),
                ),

                const SizedBox(height: 24),

                // Submit Button (Pill actionEmerald)
                AppButton(
                  text: 'Kirim Kritik & Saran',
                  icon: Icons.send_rounded,
                  backgroundColor: actionEmerald,
                  textColor: Colors.white,
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
