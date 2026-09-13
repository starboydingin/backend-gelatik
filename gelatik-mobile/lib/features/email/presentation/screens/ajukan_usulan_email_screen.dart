import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/civic_form.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/email_provider.dart';
import 'usulan_email_list_screen.dart';

/// AjukanUsulanEmailScreen — Form Pengajuan Email Resmi Pegawai (M-F)
class AjukanUsulanEmailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pegawaiData;

  const AjukanUsulanEmailScreen({super.key, required this.pegawaiData});

  @override
  ConsumerState<AjukanUsulanEmailScreen> createState() =>
      _AjukanUsulanEmailScreenState();
}

class _AjukanUsulanEmailScreenState
    extends ConsumerState<AjukanUsulanEmailScreen> {
  late TextEditingController _emailPribadiController;
  String? _emailPribadiError;

  @override
  void initState() {
    super.initState();
    _emailPribadiController = TextEditingController(
      text: widget.pegawaiData['email_pribadi'] ?? '',
    );
  }

  @override
  void dispose() {
    _emailPribadiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailPribadiError = null;
    });

    final emailText = _emailPribadiController.text.trim();
    if (emailText.isEmpty || !emailText.contains('@')) {
      setState(() => _emailPribadiError = 'Email pribadi tidak valid');
      return;
    }

    final success = await ref
        .read(emailProvider.notifier)
        .tambahUsulanEmail(
          pegawaiData: widget.pegawaiData,
          emailPribadi: emailText,
        );

    if (!mounted) return;

    if (success) {
      AppNotification.showSuccess(
        context,
        'Usulan email resmi berhasil diajukan!',
      );

      // Redirect to UsulanEmailListScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UsulanEmailListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentNavy = AppColors.accentNavy(context);
    final mutedText = AppColors.mutedText(context);
    final state = ref.watch(emailProvider);

    final nama = widget.pegawaiData['nama'] ?? 'Pegawai';
    final nip = widget.pegawaiData['nip_baru'] ?? '-';
    final opd = widget.pegawaiData['opd'] ?? '-';
    final jabatan = widget.pegawaiData['jabatan'] ?? '-';
    final emailUsulan = widget.pegawaiData['email_usulan'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Usulan Email'),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CivicFormIntro(
                eyebrow: 'Administrasi akun dinas',
                title: 'Verifikasi usulan email ASN',
                description:
                    'Periksa identitas pegawai terpilih, lalu tentukan alamat kontak untuk menerima informasi aktivasi.',
                icon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 16),
              // Ringkasan Data Pegawai Terpilih (Read-only Bento Card)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentNavy.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: accentNavy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Pegawai Terpilih',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                              Text(
                                nama,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _buildDataRow('NIP Pegawai', nip, primaryTeal, mutedText),
                    const SizedBox(height: 6),
                    _buildDataRow('Jabatan', jabatan, primaryTeal, mutedText),
                    const SizedBox(height: 6),
                    _buildDataRow(
                      'OPD / Instansi',
                      opd,
                      primaryTeal,
                      mutedText,
                    ),
                    const SizedBox(height: 6),
                    _buildDataRow(
                      'Email Usulan (Sistem)',
                      emailUsulan,
                      primaryTeal,
                      mutedText,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Usulan Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lengkapi Kontak Verifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emailPribadiController,
                      labelText: 'Email Pribadi Aktif',
                      hintText: 'nama@gmail.com / yahoo.com',
                      errorText: _emailPribadiError,
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email pribadi digunakan oleh tim BKD untuk mengirimkan kredensial sementara setelah usulan disetujui.',
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedText,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Ajukan Usulan Email',
                      icon: Icons.send_rounded,
                      backgroundColor: actionEmerald,
                      textColor: Colors.white,
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    Color primaryTeal,
    Color mutedText, {
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: TextStyle(fontSize: 12, color: mutedText)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? primaryTeal : null,
            ),
          ),
        ),
      ],
    );
  }
}
