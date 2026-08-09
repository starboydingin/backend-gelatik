import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../konsultasi/presentation/screens/buat_konsultasi_screen.dart';
import '../../providers/internet_provider.dart';

/// SelfAssessmentScreen — Card FAQ mandiri sebelum buat pengaduan internet (M-E)
class SelfAssessmentScreen extends ConsumerStatefulWidget {
  const SelfAssessmentScreen({super.key});

  @override
  ConsumerState<SelfAssessmentScreen> createState() =>
      _SelfAssessmentScreenState();
}

class _SelfAssessmentScreenState extends ConsumerState<SelfAssessmentScreen> {
  bool _readFaqChecked = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(internetProvider.notifier).loadFaq());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentGold = AppColors.accentGold(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(internetProvider);
    final faqs = state.listFaq;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Assessment Internet'),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info Card (Bento style)
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_rounded,
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
                            'Pemeriksaan Mandiri Kendala Internet',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bacalah petunjuk penanganan cepat berikut sebelum mengajukan tiket pengaduan.',
                            style: TextStyle(fontSize: 12, color: mutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Pertanyaan & Langkah Penanganan FAQ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal,
                ),
              ),
              const SizedBox(height: 12),

              // FAQ Items Cards
              ...faqs.map((faq) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              size: 18,
                              color: primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                faq['pertanyaan'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Text(
                          faq['jawaban'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Checkbox Mandiri
              AppCard(
                child: Row(
                  children: [
                    Checkbox(
                      value: _readFaqChecked,
                      activeColor: primaryTeal,
                      onChanged: (val) {
                        setState(() {
                          _readFaqChecked = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _readFaqChecked = !_readFaqChecked;
                          });
                        },
                        child: Text(
                          'Saya sudah membaca dan mencoba langkah FAQ di atas, tetapi kendala masih terjadi.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Button Continue to BuatKonsultasiScreen
              AppButton(
                text: 'Lanjut ke Form Pengaduan Internet',
                icon: Icons.arrow_forward_rounded,
                backgroundColor: actionEmerald,
                textColor: Colors.white,
                onPressed: _readFaqChecked
                    ? () {
                        // Redirect to BuatKonsultasiScreen (REUSE)
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const BuatKonsultasiScreen(),
                          ),
                        );
                      }
                    : null, // Disabled if not checked
              ),
            ],
          ),
        ),
      ),
    );
  }
}
