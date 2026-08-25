import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/wa_notification_provider.dart';

/// NotifikasiWhatsAppScreen — Pengaturan Notifikasi WhatsApp (F-WA)
class NotifikasiWhatsAppScreen extends ConsumerStatefulWidget {
  const NotifikasiWhatsAppScreen({super.key});

  @override
  ConsumerState<NotifikasiWhatsAppScreen> createState() =>
      _NotifikasiWhatsAppScreenState();
}

class _NotifikasiWhatsAppScreenState
    extends ConsumerState<NotifikasiWhatsAppScreen> {
  final TextEditingController _waController = TextEditingController();
  String? _waError;
  bool _isSubscribed = false;
  bool _initialized = false;
  bool _numberEdited = false;

  void _syncSubscriptionFields() {
    if (!mounted || _numberEdited) return;
    final subscription = ref.read(waNotificationProvider).subscription;
    _waController.text = subscription.waNumber;
    _isSubscribed = subscription.isSubscribed;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubscription());
  }

  Future<void> _loadSubscription() async {
    if (!ref.read(authProvider).isLoggedIn) return;
    await ref.read(waNotificationProvider.notifier).loadSubscription();
    if (!mounted || _numberEdited) return;
    setState(_syncSubscriptionFields);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final sub = ref.read(waNotificationProvider).subscription;
      _waController.text = sub.waNumber;
      _isSubscribed = sub.isSubscribed;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _waController.dispose();
    super.dispose();
  }

  void _handleToggle(bool value) {
    if (value) {
      // Validate number before turning ON
      final error = WaNotificationNotifier.validateWaNumber(_waController.text);
      if (error != null) {
        setState(() {
          _waError = error;
          _isSubscribed = false;
        });
        return;
      }
    }
    setState(() {
      _waError = null;
      _isSubscribed = value;
    });
  }

  Future<void> _handleSave() async {
    final number = _waController.text.trim();
    if (_isSubscribed) {
      final error = WaNotificationNotifier.validateWaNumber(number);
      if (error != null) {
        setState(() {
          _waError = error;
        });
        return;
      }
    }

    setState(() {
      _waError = null;
    });

    final success = await ref
        .read(waNotificationProvider.notifier)
        .saveSubscription(waNumber: number, isSubscribed: _isSubscribed);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan Notifikasi WhatsApp berhasil disimpan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      final message = ref.read(waNotificationProvider).errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WaNotificationState>(waNotificationProvider, (previous, next) {
      if (previous?.subscription == next.subscription || _numberEdited) return;
      setState(_syncSubscriptionFields);
    });

    final theme = Theme.of(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final waState = ref.watch(waNotificationProvider);
    final sub = waState.subscription;
    final accountCreatedAt = ref.watch(
      authProvider.select((state) => state.currentUser?.createdAt),
    );
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    // Official WhatsApp Brand Color (Khusus ikon representasi platform eksternal WA)
    const waBrandColor = Color(0xFF25D366);

    return Scaffold(
      appBar: const GelatikPageHeader(
        title: 'Notifikasi WhatsApp',
        showBack: true,
        actions: [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bento Card Penjelasan Singkat
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: waBrandColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: waBrandColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.chat_rounded,
                            color: waBrandColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Layanan Notifikasi WA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dapatkan notifikasi status pengajuan langsung ke WhatsApp Anda.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: mutedText,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (sub.isSubscribed && accountCreatedAt != null) ...[
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: actionEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: actionEmerald.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: actionEmerald,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Akun terdaftar sejak ${dateFormat.format(accountCreatedAt)}',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: actionEmerald,
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

              const SizedBox(height: 20),

              // Form Settings Bento Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENGATURAN NOMOR & STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Divider(height: 20),

                    // AppTextField "Nomor WhatsApp"
                    AppTextField(
                      labelText: 'Nomor WhatsApp',
                      hintText: 'Misal: 081234567890',
                      controller: _waController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      errorText: _waError,
                      onChanged: (val) {
                        _numberEdited = true;
                        if (_waError != null) {
                          setState(() {
                            _waError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '* Field ini terpisah dari No. HP profil utama. Wajib diawali 08/628 (10–15 digit).',
                      style: TextStyle(fontSize: 11, color: mutedText),
                    ),

                    const SizedBox(height: 24),

                    // Toggle Switch Besar "Aktifkan Notifikasi WhatsApp"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isSubscribed ? actionEmerald : strokeColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Aktifkan Notifikasi WhatsApp',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isSubscribed
                                      ? 'Notifikasi aktif untuk nomor ini'
                                      : 'Notifikasi saat ini dinonaktifkan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isSubscribed,
                            activeTrackColor: actionEmerald,
                            onChanged: _handleToggle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tombol "Simpan"
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Simpan Pengaturan',
                  icon: Icons.save_rounded,
                  variant: AppButtonVariant.filled,
                  isLoading: waState.isLoading,
                  onPressed: _handleSave,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
