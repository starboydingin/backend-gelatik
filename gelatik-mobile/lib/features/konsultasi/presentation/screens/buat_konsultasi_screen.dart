import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/konsultasi_provider.dart';

class BuatKonsultasiScreen extends ConsumerStatefulWidget {
  const BuatKonsultasiScreen({super.key});

  @override
  ConsumerState<BuatKonsultasiScreen> createState() =>
      _BuatKonsultasiScreenState();
}

class _BuatKonsultasiScreenState extends ConsumerState<BuatKonsultasiScreen> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();

  String _topik = 'Jaringan & Internet';
  String? _judulError;
  String? _pesanError;

  @override
  void dispose() {
    _judulController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _judulError = null;
      _pesanError = null;
    });

    if (_judulController.text.trim().isEmpty) {
      setState(() => _judulError = 'Judul konsultasi wajib diisi');
      return;
    }

    if (_pesanController.text.trim().isEmpty) {
      setState(() => _pesanError = 'Pesan konsultasi wajib diisi');
      return;
    }

    final user = ref.read(authProvider).currentUser;

    final success =
        await ref.read(konsultasiProvider.notifier).tambahKonsultasi(
              userId: user?.id ?? 1,
              judul: _judulController.text.trim(),
              pesan: _pesanController.text.trim(),
              topikNama: _topik,
            );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Konsultasi berhasil diajukan!'),
          backgroundColor: AppColors.actionEmeraldLight,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final state = ref.watch(konsultasiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Konsultasi TIK'),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Konsultasi TIK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _topik,
                  decoration: const InputDecoration(
                    labelText: 'Topik Konsultasi',
                    prefixIcon: Icon(Icons.topic_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'Jaringan & Internet',
                        child: Text('Jaringan & Internet')),
                    DropdownMenuItem(
                        value: 'Domain & Hosting',
                        child: Text('Domain & Hosting')),
                    DropdownMenuItem(
                        value: 'Aplikasi Pegawai',
                        child: Text('Aplikasi Pegawai')),
                    DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _topik = val);
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  labelText: 'Judul Konsultasi',
                  hintText: 'Tuliskan judul singkat kendala/pertanyaan',
                  controller: _judulController,
                  errorText: _judulError,
                  prefixIcon: const Icon(Icons.subtitles_outlined),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  labelText: 'Pesan / Deskripsi Kendala',
                  hintText: 'Jelaskan rincian kendala yang dialami...',
                  controller: _pesanController,
                  maxLines: 4,
                  errorText: _pesanError,
                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: 'Kirim Konsultasi',
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
