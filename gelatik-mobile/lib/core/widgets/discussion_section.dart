import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import 'app_card.dart';
import 'app_notification.dart';

class DiscussionSection extends ConsumerStatefulWidget {
  final String serviceType; // 'pinjam', 'usulan_email', 'email', 'konsultasi'
  final int recordId;
  final String status;

  const DiscussionSection({
    super.key,
    required this.serviceType,
    required this.recordId,
    required this.status,
  });

  @override
  ConsumerState<DiscussionSection> createState() => _DiscussionSectionState();
}

class _DiscussionSectionState extends ConsumerState<DiscussionSection> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String get _normalizedServiceType {
    final t = widget.serviceType.toLowerCase();
    if (t == 'email') return 'usulan_email';
    return t;
  }

  bool get _canComment {
    final s = widget.status.trim().toLowerCase();
    return s == 'diproses' || s == 'proses' || s == 'ditolak';
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void didUpdateWidget(covariant DiscussionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordId != widget.recordId ||
        oldWidget.serviceType != widget.serviceType) {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get('/$_normalizedServiceType/${widget.recordId}/comments');

      if (response.data != null && response.data['data'] is List) {
        if (mounted) {
          setState(() {
            _comments = List<Map<String, dynamic>>.from(response.data['data']);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_canComment) {
      AppNotification.showWarning(
        context,
        'Diskusi hanya dapat dilakukan saat pengajuan berstatus Diproses atau Ditolak.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.post(
        '/$_normalizedServiceType/${widget.recordId}/comments',
        data: {'pesan': text},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _messageController.clear();
        FocusScope.of(context).unfocus();
        AppNotification.showSuccess(context, 'Pesan berhasil dikirim.');
        await _loadComments();
      } else {
        final msg = response.data?['message'] ?? 'Gagal mengirim komentar.';
        AppNotification.showError(context, msg.toString());
      }
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final data = dioErr.response?.data;
      final msg = data is Map ? (data['message'] ?? 'Gagal mengirim komentar.') : 'Terjadi kesalahan jaringan.';
      AppNotification.showError(context, msg.toString());
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Gagal mengirim pesan: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final mutedText = AppColors.mutedText(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            children: [
              Icon(Icons.forum_outlined, size: 20, color: primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Diskusi & Tindak Lanjut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_comments.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryTeal,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: _isLoading ? null : _loadComments,
                tooltip: 'Segarkan Komentar',
              ),
            ],
          ),
          const Divider(height: 20),

          // Comment list
          if (_isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ] else if (_comments.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 36,
                      color: mutedText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada tanggapan atau pesan diskusi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final isAdmin = comment['is_admin'] == true ||
                    (comment['author_role']?.toString().toLowerCase() == 'admin' ||
                        comment['author_role']?.toString().toLowerCase() == 'superadmin');
                final author = comment['author_name']?.toString() ??
                    (isAdmin ? 'Petugas Helpdesk' : 'Pemohon');
                final message = comment['pesan']?.toString() ?? '';
                final createdAtStr = comment['created_at']?.toString();
                DateTime? createdAt;
                if (createdAtStr != null) {
                  createdAt = DateTime.tryParse(createdAtStr);
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? (isDark
                            ? actionEmerald.withValues(alpha: 0.1)
                            : const Color(0xFFF0FDF4))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAdmin
                          ? actionEmerald.withValues(alpha: 0.3)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? actionEmerald
                                  : (isDark
                                      ? Colors.blueGrey[700]
                                      : const Color(0xFF475569)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isAdmin ? 'Petugas' : 'Pemohon',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              author,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              GelatikDateFormatter.dateTime(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedText,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // Input field or status locked banner
          if (!_canComment) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withValues(alpha: 0.1)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.amber.withValues(alpha: 0.3)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark ? Colors.amber[300] : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diskusi dua arah hanya dapat dilakukan saat pengajuan berstatus Diproses atau Ditolak.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.amber[200]
                            : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isSubmitting,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendComment(),
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan diskusi atau tanggapan...',
                      hintStyle: TextStyle(fontSize: 13, color: mutedText),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSubmitting ? null : _sendComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: primaryTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
