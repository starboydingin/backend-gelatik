import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../email/presentation/screens/usulan_email_detail_screen.dart';
import '../../../email/repositories/email_repository.dart';
import '../../../konsultasi/presentation/screens/konsultasi_detail_screen.dart';
import '../../../konsultasi/repositories/konsultasi_repository.dart';
import '../../../peminjaman/presentation/screens/peminjaman_detail_screen.dart';
import '../../../peminjaman/repositories/peminjaman_repository.dart';
import '../../models/gelatik_notification.dart';
import '../../repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<GelatikNotification> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref
          .read(notificationRepositoryProvider)
          .getNotifications();
      if (mounted) setState(() => _items = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(GelatikNotification item) async {
    if (!item.isRead) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
        if (mounted) {
          setState(() {
            _items = _items
                .map(
                  (entry) => entry.id == item.id
                      ? entry.copyWith(isRead: true)
                      : entry,
                )
                .toList(growable: false);
          });
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final resourceId = item.resourceId;
    try {
      final resourceType = item.resourceType?.toLowerCase() ?? '';
      if (resourceId != null && resourceType.contains('konsult')) {
        final detail = await ref
            .read(konsultasiRepositoryProvider)
            .getDetail(resourceId);
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KonsultasiDetailScreen(konsultasi: detail),
            ),
          );
        }
        return;
      }
      if (resourceId != null && resourceType.contains('pinjam')) {
        final detail = await ref
            .read(peminjamanRepositoryProvider)
            .getPeminjamanDetail(resourceId);
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PeminjamanDetailScreen(pinjam: detail),
            ),
          );
        }
        return;
      }
      if (resourceId != null && resourceType.contains('email')) {
        final items = await ref.read(emailRepositoryProvider).getUsulan();
        final detail = items
            .where((entry) => entry.id == resourceId)
            .firstOrNull;
        if (detail != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UsulanEmailDetailScreen(usulan: detail),
            ),
          );
          return;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detail belum dapat dibuka: $error')),
        );
      }
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(item.message),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: GelatikPageHeader(
      title: 'Notifikasi',
      showBack: true,
      actions: [
        TextButton(
          onPressed: _items.any((item) => !item.isRead)
              ? () async {
                  await ref.read(notificationRepositoryProvider).markAllRead();
                  await _load();
                }
              : null,
          child: const Text('Baca semua'),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!),
                ),
              ],
            )
          : _items.isEmpty
          ? const Center(child: Text('Belum ada notifikasi.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return AppCard(
                  onTap: () => _open(item),
                  backgroundColor: item.isRead
                      ? null
                      : AppColors.actionEmerald(context).withValues(alpha: .08),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isRead
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: AppColors.primaryTeal(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.createdAt != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                GelatikDateFormatter.dateTime(item.createdAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText(context),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!item.isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 8, top: 4),
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFF10B981),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    ),
  );
}
