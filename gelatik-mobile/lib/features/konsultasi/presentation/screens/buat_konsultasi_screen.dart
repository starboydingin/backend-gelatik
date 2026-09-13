import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/app_searchable_select.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/civic_form.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../providers/konsultasi_provider.dart';

class BuatKonsultasiScreen extends ConsumerStatefulWidget {
  final int? initialTopikId;

  const BuatKonsultasiScreen({super.key, this.initialTopikId});

  @override
  ConsumerState<BuatKonsultasiScreen> createState() =>
      _BuatKonsultasiScreenState();
}

class _BuatKonsultasiScreenState extends ConsumerState<BuatKonsultasiScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  int? _topikId;
  String? _topikError;
  String? _judulError;
  String? _deskripsiError;

  @override
  void initState() {
    super.initState();
    _topikId = widget.initialTopikId;
    Future.microtask(() => ref.read(konsultasiProvider.notifier).loadTopik());
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String? _fieldError(KonsultasiState state, String key) {
    final value = state.validationErrors[key];
    if (value is List && value.isNotEmpty) return value.first.toString();
    return value is String ? value : null;
  }

  Future<void> _submit() async {
    setState(() {
      _topikError = _topikId == null ? 'Topik wajib dipilih' : null;
      _judulError = _judulController.text.trim().isEmpty
          ? 'Judul konsultasi wajib diisi'
          : null;
      _deskripsiError = _deskripsiController.text.trim().isEmpty
          ? 'Deskripsi konsultasi wajib diisi'
          : null;
    });
    if (_topikError != null || _judulError != null || _deskripsiError != null) {
      return;
    }
    final success = await ref
        .read(konsultasiProvider.notifier)
        .tambahKonsultasi(
          topikId: _topikId!,
          judul: _judulController.text,
          deskripsi: _deskripsiController.text,
        );
    if (!mounted) return;
    final state = ref.read(konsultasiProvider);
    if (success) {
      AppNotification.showSuccess(
        context,
        'Konsultasi berhasil diajukan!',
      );
      Navigator.of(context).pop();
    } else {
      setState(() {
        _topikError = _fieldError(state, 'topik_id') ?? _topikError;
        _judulError = _fieldError(state, 'judul') ?? _judulError;
        _deskripsiError = _fieldError(state, 'deskripsi') ?? _deskripsiError;
      });
      AppNotification.showError(
        context,
        state.errorMessage ?? 'Gagal mengirim.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(konsultasiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Konsultasi TIK'),
        centerTitle: true,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CivicFormIntro(
                eyebrow: 'Kanal bantuan resmi',
                title: 'Ceritakan kebutuhan TIK Anda',
                description:
                    'Pilih bidang layanan dan sampaikan situasi secara ringkas agar permintaan langsung diteruskan ke petugas yang tepat.',
                icon: Icons.support_agent_rounded,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.colorPrimary,
                          foregroundColor: Colors.white,
                          child: Text('1'),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Lengkapi detail konsultasi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.isTopikLoading)
                      const LinearProgressIndicator()
                    else
                      AppSearchableSelect<int>(
                        key: const Key('topik-dropdown'),
                        labelText: 'Topik Konsultasi',
                        hintText: 'Pilih topik yang sesuai',
                        searchHint: 'Cari topik konsultasi…',
                        value: _topikId,
                        errorText: _topikError,
                        prefixIcon: const Icon(Icons.topic_outlined),
                        enabled: !state.isSubmitting,
                        options: state.topiks
                            .where(
                              (topik) =>
                                  topik.status == null || topik.status == '1',
                            )
                            .map(
                              (topik) => SearchableSelectOption<int>(
                                value: topik.id,
                                label: topik.nama,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setState(() {
                          _topikId = value;
                          _topikError = null;
                        }),
                      ),
                    if (!state.isTopikLoading && state.topiks.isEmpty) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref
                            .read(konsultasiProvider.notifier)
                            .loadTopik(force: true),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Muat ulang topik'),
                      ),
                    ],
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
                      controller: _deskripsiController,
                      maxLines: 4,
                      errorText: _deskripsiError,
                      prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.colorBorder)),
          ),
          child: AppButton(
            text: 'Kirim Konsultasi',
            icon: Icons.send_rounded,
            backgroundColor: AppColors.colorAccent,
            textColor: AppColors.colorTextPrimary,
            isLoading: state.isSubmitting,
            onPressed: state.isSubmitting ? null : _submit,
          ),
        ),
      ),
    );
  }
}
