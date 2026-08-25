import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/rating_repository.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final int feedbackId;

  const RatingScreen({super.key, required this.feedbackId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _value = 0;
  bool _hadRating = false;
  bool _loading = true;
  bool _saving = false;
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
    _realtimeSubscription = ref
        .read(realtimeSocketServiceProvider)
        .events
        .where((event) => event.type == 'data.sync' || event.type == 'insights.sync')
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final value = await ref.read(ratingRepositoryProvider).getRating();
      if (mounted) {
        setState(() {
          _value = value ?? 0;
          _hadRating = value != null;
        });
      }
    } catch (_) {
      // Rating may be empty for a new account; the form remains usable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_value == 0) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(ratingRepositoryProvider)
          .saveRating(
            _value,
            exists: _hadRating,
            feedbackId: widget.feedbackId,
          );
      if (!mounted) {
        return;
      }
      setState(() => _hadRating = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih atas penilaian Anda.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(title: 'Rating Layanan', showBack: true),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.star_outline_rounded,
                            color: AppColors.accentGold(context),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Bagaimana pengalaman Anda?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Penilaian membantu kami meningkatkan layanan TIK.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            alignment: WrapAlignment.center,
                            children: List.generate(
                              5,
                              (index) => IconButton(
                                onPressed: () =>
                                    setState(() => _value = index + 1),
                                iconSize: 38,
                                icon: Icon(
                                  index < _value
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: AppColors.accentGold(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          AppButton(
                            text: _hadRating
                                ? 'Perbarui penilaian'
                                : 'Kirim penilaian',
                            backgroundColor: AppColors.actionEmerald(context),
                            isLoading: _saving,
                            onPressed: _value == 0 ? null : _save,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
