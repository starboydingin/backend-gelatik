import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../info_alat/models/master_item_model.dart';
import '../../../info_alat/presentation/screens/pilih_aset_screen.dart';
import '../../providers/peminjaman_provider.dart';
import 'peminjaman_list_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// AjukanPeminjamanScreen — Layar Wizard 2-Step Pengajuan Peminjaman Aset TIK
class AjukanPeminjamanScreen extends ConsumerStatefulWidget {
  const AjukanPeminjamanScreen({super.key});

  @override
  ConsumerState<AjukanPeminjamanScreen> createState() =>
      _AjukanPeminjamanScreenState();
}

class _AjukanPeminjamanScreenState
    extends ConsumerState<AjukanPeminjamanScreen> {
  int _currentStep = 1;

  // Step 1: Selected quantities (itemId -> qty)
  final Map<int, int> _selectedQuantities = {};

  // Step 2: Form Controllers & State
  late TextEditingController _namaPicController;
  late TextEditingController _jabatanPicController;
  late TextEditingController _instansiPicController;
  late TextEditingController _kontakPicController;
  late TextEditingController _nomorIdentitasController;
  late TextEditingController _alamatPeminjamController;
  late TextEditingController _durasiCountController;
  late TextEditingController _keteranganController;

  String _jenisIdentitas = 'NIP';
  String _jenisDurasi = 'harian'; // harian, jam, menit
  DateTime _tanggalMulai = DateTime.now();
  final TimeOfDay _jamMulai = const TimeOfDay(hour: 8, minute: 0);
  String? _uploadedFileName;
  bool _agreeTerms = false;

  // Errors
  String? _namaPicError;
  String? _jabatanPicError;
  String? _instansiPicError;
  String? _kontakPicError;
  String? _nomorIdentitasError;
  String? _alamatPeminjamError;
  String? _durasiError;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;

    _namaPicController = TextEditingController(text: user?.name ?? '');
    _jabatanPicController =
        TextEditingController(text: 'Pranata Komputer Ahli Muda');
    _instansiPicController = TextEditingController(text: user?.namaOpd ?? '');
    _kontakPicController = TextEditingController(text: user?.noHp ?? '');
    _nomorIdentitasController =
        TextEditingController(text: '198804122014031002');
    _alamatPeminjamController =
        TextEditingController(text: 'Jl. Wolter Monginsidi No. 69, Bandar Lampung');
    _durasiCountController = TextEditingController(text: '1');
    _keteranganController = TextEditingController();
  }

  @override
  void dispose() {
    _namaPicController.dispose();
    _jabatanPicController.dispose();
    _instansiPicController.dispose();
    _kontakPicController.dispose();
    _nomorIdentitasController.dispose();
    _alamatPeminjamController.dispose();
    _durasiCountController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  int get _totalSelectedItemsCount {
    return _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  Map<MasterItemModel, int> _getSelectedItemsMap(List<MasterItemModel> masterItems) {
    final Map<MasterItemModel, int> map = {};
    for (final item in masterItems) {
      final qty = _selectedQuantities[item.id] ?? 0;
      if (qty > 0) {
        map[item] = qty;
      }
    }
    return map;
  }

  DateTime get _estimatedEndDate {
    final durasi = int.tryParse(_durasiCountController.text) ?? 1;
    final start = DateTime(
      _tanggalMulai.year,
      _tanggalMulai.month,
      _tanggalMulai.day,
      _jamMulai.hour,
      _jamMulai.minute,
    );

    if (_jenisDurasi == 'jam') {
      return start.add(Duration(hours: durasi));
    } else if (_jenisDurasi == 'menit') {
      return start.add(Duration(minutes: durasi));
    } else {
      // harian
      return start.add(Duration(days: durasi));
    }
  }

  String _formatDateTime(DateTime dt, String jenisDurasi) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    if (jenisDurasi == 'jam' || jenisDurasi == 'menit') {
      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minStr = dt.minute.toString().padLeft(2, '0');
      return '$dateStr, $hourStr:$minStr';
    }
    return dateStr;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMulai,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggalMulai = picked;
      });
    }
  }

  Future<void> _handleSubmit(List<MasterItemModel> masterItems) async {
    setState(() {
      _namaPicError = null;
      _jabatanPicError = null;
      _instansiPicError = null;
      _kontakPicError = null;
      _nomorIdentitasError = null;
      _alamatPeminjamError = null;
      _durasiError = null;
      _termsError = null;
    });

    bool isValid = true;
    if (_namaPicController.text.trim().isEmpty) {
      setState(() => _namaPicError = 'Nama PIC wajib diisi');
      isValid = false;
    }
    if (_jabatanPicController.text.trim().isEmpty) {
      setState(() => _jabatanPicError = 'Jabatan PIC wajib diisi');
      isValid = false;
    }
    if (_instansiPicController.text.trim().isEmpty) {
      setState(() => _instansiPicError = 'Instansi PIC wajib diisi');
      isValid = false;
    }
    if (_kontakPicController.text.trim().isEmpty) {
      setState(() => _kontakPicError = 'Kontak PIC wajib diisi');
      isValid = false;
    }
    if (_nomorIdentitasController.text.trim().isEmpty) {
      setState(() => _nomorIdentitasError = 'Nomor identitas wajib diisi');
      isValid = false;
    }
    if (_alamatPeminjamController.text.trim().isEmpty) {
      setState(() => _alamatPeminjamError = 'Alamat peminjam wajib diisi');
      isValid = false;
    }
    final durasi = int.tryParse(_durasiCountController.text.trim());
    if (durasi == null || durasi <= 0) {
      setState(() => _durasiError = 'Durasi harus berupa angka minimal 1');
      isValid = false;
    }
    if (!_agreeTerms) {
      setState(() => _termsError = 'Harap menyetujui syarat & ketentuan');
      isValid = false;
    }

    if (!isValid) return;

    final user = ref.read(authProvider).currentUser;
    final selectedItemsMap = _getSelectedItemsMap(masterItems);

    final success = await ref.read(peminjamanProvider.notifier).submitPengajuan(
          userId: user?.id ?? 1,
          namaPic: _namaPicController.text.trim(),
          jabatanPic: _jabatanPicController.text.trim(),
          instansiPic: _instansiPicController.text.trim(),
          kontakPic: _kontakPicController.text.trim(),
          jenisIdentitas: _jenisIdentitas,
          nomorIdentitas: _nomorIdentitasController.text.trim(),
          alamatPeminjam: _alamatPeminjamController.text.trim(),
          jenisDurasi: _jenisDurasi,
          tanggalMulai: _tanggalMulai,
          jamMulai: '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}',
          durasiPeminjaman: durasi!,
          keterangan: _keteranganController.text.trim().isNotEmpty
              ? _keteranganController.text.trim()
              : null,
          urlDokumen: _uploadedFileName,
          selectedItemsWithQuantity: selectedItemsMap,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Pengajuan peminjaman berhasil dikirim!'),
              ),
            ],
          ),
          backgroundColor: AppColors.actionEmeraldLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Redirect ke PeminjamanListScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PeminjamanListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final accentNavy = AppColors.accentNavy(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final peminjamanState = ref.watch(peminjamanProvider);
    final masterItems = peminjamanState.listMasterItem;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Peminjaman Aset'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // HEADER STEPPER PROGRESS BAR (Mockup Compliant)
              // ---------------------------------------------------------------
              _buildStepperHeader(context),

              const SizedBox(height: 24),

              // ---------------------------------------------------------------
              // STEP 1 CONTENT: PILIH ASET MULTI-SELECT
              // ---------------------------------------------------------------
              if (_currentStep == 1) ...[
                Text(
                  'Pilih Aset TIK yang Ingin Dipinjam',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Anda dapat memilih lebih dari satu aset dan menentukan jumlahnya.',
                  style: TextStyle(fontSize: 13, color: mutedText),
                ),
                const SizedBox(height: 16),

                PilihAsetWidget(
                  masterItems: masterItems,
                  selectedQuantities: _selectedQuantities,
                  onQuantityChanged: (item, newQty) {
                    setState(() {
                      if (newQty <= 0) {
                        _selectedQuantities.remove(item.id);
                      } else {
                        _selectedQuantities[item.id] = newQty;
                      }
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Button Lanjut ke Step 2 (Aktif jika minimal 1 item dipilih)
                AppButton(
                  text: _totalSelectedItemsCount > 0
                      ? 'Lanjut ke Detail Pinjam ($_totalSelectedItemsCount Aset)'
                      : 'Pilih Minimal 1 Aset',
                  icon: Icons.arrow_forward_rounded,
                  backgroundColor: _totalSelectedItemsCount > 0
                      ? actionEmerald
                      : strokeColor,
                  textColor: _totalSelectedItemsCount > 0
                      ? Colors.white
                      : mutedText,
                  onPressed: _totalSelectedItemsCount > 0
                      ? () => setState(() => _currentStep = 2)
                      : null,
                ),
              ],

              // ---------------------------------------------------------------
              // STEP 2 CONTENT: DETAIL PINJAM FORM (Mockup Bento Card Compliant)
              // ---------------------------------------------------------------
              if (_currentStep == 2) ...[
                // Bento Card Form utama
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Detail Peminjaman',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _currentStep = 1),
                            icon: Icon(Icons.edit_outlined,
                                size: 16, color: primaryTeal),
                            label: Text(
                              'Ubah Aset',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 1. Ringkasan Aset Terpilih (Chip / Read-only)
                      Text(
                        'Aset Terpilih:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getSelectedItemsMap(masterItems)
                            .entries
                            .map((e) {
                          return Chip(
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            side: BorderSide(color: strokeColor, width: 1),
                            avatar: CircleAvatar(
                              backgroundColor: primaryTeal,
                              child: Text(
                                '${e.value}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            label: Text(
                              e.key.nama,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // 2. Field PIC Details
                      Text(
                        'Informasi Penanggung Jawab (PIC)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),

                      AppTextField(
                        labelText: 'Nama PIC',
                        hintText: 'Nama lengkap PIC',
                        controller: _namaPicController,
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: _namaPicError,
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'Jabatan PIC',
                        hintText: 'Jabatan resmi',
                        controller: _jabatanPicController,
                        prefixIcon: const Icon(Icons.work_outline),
                        errorText: _jabatanPicError,
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'Instansi / OPD PIC',
                        hintText: 'Nama instansi',
                        controller: _instansiPicController,
                        prefixIcon: const Icon(Icons.business_outlined),
                        errorText: _instansiPicError,
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'No. Kontak PIC (WhatsApp)',
                        hintText: '081234567890',
                        controller: _kontakPicController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_android_outlined),
                        errorText: _kontakPicError,
                      ),
                      const SizedBox(height: 12),

                      // Dropdown Jenis Identitas
                      DropdownButtonFormField<String>(
                        initialValue: _jenisIdentitas,
                        decoration: InputDecoration(
                          labelText: 'Jenis Identitas',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'KTP', child: Text('KTP')),
                          DropdownMenuItem(value: 'SIM', child: Text('SIM')),
                          DropdownMenuItem(
                              value: 'Passport', child: Text('Passport')),
                          DropdownMenuItem(value: 'NIP', child: Text('NIP')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _jenisIdentitas = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'Nomor Identitas',
                        hintText: 'Masukkan nomor KTP/NIP',
                        controller: _nomorIdentitasController,
                        prefixIcon:
                            const Icon(Icons.credit_card_outlined),
                        errorText: _nomorIdentitasError,
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'Alamat Peminjam / Lokasi Penggunaan',
                        hintText: 'Alamat kantor / tempat penggunaan',
                        controller: _alamatPeminjamController,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        errorText: _alamatPeminjamError,
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // 3. Durasi Peminjaman
                      Text(
                        'Waktu & Durasi Peminjaman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectDate,
                              child: AbsorbPointer(
                                child: AppTextField(
                                  labelText: 'Tanggal Mulai',
                                  hintText: 'Pilih Tanggal',
                                  controller: TextEditingController(
                                    text:
                                        '${_tanggalMulai.day}/${_tanggalMulai.month}/${_tanggalMulai.year}',
                                  ),
                                  prefixIcon: const Icon(
                                      Icons.calendar_today_outlined),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _jenisDurasi,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Durasi',
                                prefixIcon: Icon(Icons.timer_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'harian', child: Text('Harian')),
                                DropdownMenuItem(
                                    value: 'jam', child: Text('Jam')),
                                DropdownMenuItem(
                                    value: 'menit', child: Text('Menit')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _jenisDurasi = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      AppTextField(
                        labelText: 'Jumlah Durasi',
                        hintText: 'misal: 3',
                        controller: _durasiCountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        errorText: _durasiError,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),

                      // Read-only dynamic preview "Estimasi selesai: {tanggal terhitung}"
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: strokeColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_available_rounded,
                                size: 18, color: primaryTeal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estimasi selesai: ${_formatDateTime(_estimatedEndDate, _jenisDurasi)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // 4. Textarea Keterangan (opsional)
                      AppTextField(
                        labelText: 'Keterangan (opsional)',
                        hintText:
                            'Tuliskan tujuan peminjaman dan keperluan acara...',
                        controller: _keteranganController,
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.notes_rounded),
                      ),
                      const SizedBox(height: 16),

                      // 5. Upload Dokumen (opsional) — map to field url_dokumen
                      Text(
                        'Upload Dokumen Pendukung (opsional)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Simulasi upload file
                          setState(() {
                            _uploadedFileName =
                                'Surat_Permohonan_Pinjam_${DateTime.now().millisecondsSinceEpoch % 1000}.pdf';
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _uploadedFileName != null
                                  ? primaryTeal
                                  : strokeColor,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _uploadedFileName != null
                                    ? Icons.task_rounded
                                    : Icons.cloud_upload_outlined,
                                size: 32,
                                color: _uploadedFileName != null
                                    ? actionEmerald
                                    : primaryTeal,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _uploadedFileName ??
                                    'Klik untuk upload Surat Permohonan (.pdf/.jpg)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _uploadedFileName != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _uploadedFileName != null
                                      ? primaryTeal
                                      : mutedText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (_uploadedFileName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Terpetakan ke field: url_dokumen',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: actionEmerald,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Checkbox Syarat & Ketentuan
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
                                'Saya menyetujui syarat & ketentuan peminjaman aset TIK Pemprov Lampung.',
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
                        const SizedBox(height: 4),
                        Text(
                          _termsError!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 7. Tombol "Kirim Pengajuan" (Pill Emerald, Icon Send)
                      AppButton(
                        text: 'Kirim Pengajuan',
                        icon: Icons.send_rounded,
                        backgroundColor: actionEmerald,
                        textColor: Colors.white,
                        isLoading: peminjamanState.isLoading,
                        onPressed: () => _handleSubmit(masterItems),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 8. Info Card Bawah (Bento, Icon info accentNavy)
                AppCard(
                  backgroundColor:
                      accentNavy.withValues(alpha: isDark ? 0.2 : 0.08),
                  border: Border.all(
                      color: accentNavy.withValues(alpha: 0.4), width: 1.5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: accentNavy,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Status pengajuan dapat dipantau pada menu Peminjaman. Persetujuan biasanya memakan waktu maksimal 1x24 jam kerja.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // Tab Ajukan aktif
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 1) {
            // Sudah di Ajukan
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
      ),
    );
  }

  /// Helper Builder Header Stepper Progress Bar (Linear Progress & Step Circles)
  Widget _buildStepperHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = AppColors.primaryTeal(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    return Column(
      children: [
        Row(
          children: [
            // Step 1 Circle & Label
            _buildStepCircle(
              stepNumber: 1,
              label: 'Pilih Aset',
              isActive: _currentStep >= 1,
              isCurrent: _currentStep == 1,
              primaryTeal: primaryTeal,
              strokeColor: strokeColor,
              mutedText: mutedText,
              theme: theme,
            ),

            // Progress Line Connector
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: _currentStep >= 2 ? primaryTeal : strokeColor,
              ),
            ),

            // Step 2 Circle & Label
            _buildStepCircle(
              stepNumber: 2,
              label: 'Detail Pinjam',
              isActive: _currentStep >= 2,
              isCurrent: _currentStep == 2,
              primaryTeal: primaryTeal,
              strokeColor: strokeColor,
              mutedText: mutedText,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCurrent,
    required Color primaryTeal,
    required Color strokeColor,
    required Color mutedText,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primaryTeal : theme.colorScheme.surface,
            border: Border.all(
              color: isActive ? primaryTeal : strokeColor,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : mutedText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            color: isCurrent ? primaryTeal : mutedText,
          ),
        ),
      ],
    );
  }
}
