import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/wa_notification_provider.dart';

/// Inline WhatsApp subscription form used directly below the profile identity.
class WhatsAppSettingsCard extends ConsumerStatefulWidget {
  final bool popAfterSave;

  const WhatsAppSettingsCard({super.key, this.popAfterSave = false});

  @override
  ConsumerState<WhatsAppSettingsCard> createState() =>
      _WhatsAppSettingsCardState();
}

class _WhatsAppSettingsCardState extends ConsumerState<WhatsAppSettingsCard> {
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
    if (_initialized) return;
    final subscription = ref.read(waNotificationProvider).subscription;
    _waController.text = subscription.waNumber;
    _isSubscribed = subscription.isSubscribed;
    _initialized = true;
  }

  @override
  void dispose() {
    _waController.dispose();
    super.dispose();
  }

  void _handleToggle(bool value) {
    if (value) {
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
    final error = WaNotificationNotifier.validateWaNumber(number);
    if (error != null) {
      setState(() => _waError = error);
      return;
    }

    setState(() => _waError = null);
    final success = await ref
        .read(waNotificationProvider.notifier)
        .saveSubscription(waNumber: number, isSubscribed: _isSubscribed);

    if (!mounted) return;
    if (success) {
      AppNotification.showSuccess(
        context,
        'Pengaturan Notifikasi WhatsApp berhasil disimpan.',
      );
      if (widget.popAfterSave && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    final message = ref.read(waNotificationProvider).errorMessage;
    if (message != null) {
      AppNotification.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WaNotificationState>(waNotificationProvider, (previous, next) {
      if (previous?.subscription == next.subscription || _numberEdited) return;
      setState(_syncSubscriptionFields);
    });

    final theme = Theme.of(context);
    final mutedText = AppColors.mutedText(context);
    final waState = ref.watch(waNotificationProvider);
    final accountCreatedAt = ref.watch(
      authProvider.select((state) => state.currentUser?.createdAt),
    );
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    const waBrandColor = Color(0xFF25D366);
    const settingsAccent = AppColors.colorSecondary;

    return AppCard(
      key: const Key('inline-whatsapp-settings'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.colorAuthHero,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.colorBorder),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: waBrandColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Notifikasi WhatsApp',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                key: const Key('whatsapp-subscription-switch'),
                value: _isSubscribed,
                activeTrackColor: settingsAccent,
                onChanged: _handleToggle,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Nomor WhatsApp Aktif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          AppTextField(
            key: const Key('inline-whatsapp-number'),
            labelText: 'Nomor WhatsApp',
            hintText: 'Contoh: 081234567890',
            controller: _waController,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_android_rounded),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(15),
            ],
            errorText: _waError,
            onChanged: (value) {
              _numberEdited = true;
              if (_waError != null) setState(() => _waError = null);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan nomor yang diawali 08 atau 628 (10–15 digit).',
            style: TextStyle(fontSize: 11, height: 1.4, color: mutedText),
          ),
          if (_isSubscribed && accountCreatedAt != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.colorAuthHero,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: settingsAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Akun terdaftar sejak ${dateFormat.format(accountCreatedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: settingsAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          AppButton(
            text: 'Simpan Pengaturan',
            icon: Icons.save_rounded,
            backgroundColor: settingsAccent,
            textColor: Colors.white,
            isLoading: waState.isLoading,
            onPressed: _handleSave,
          ),
        ],
      ),
    );
  }
}
