import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../models/konsultasi_model.dart';
import '../../models/konsultasi_response_model.dart';
import '../../providers/konsultasi_provider.dart';

/// KonsultasiDetailScreen — Layar Detail Thread Chat Konsultasi TIK (User vs Admin Bubbles)
class KonsultasiDetailScreen extends ConsumerStatefulWidget {
  final KonsultasiModel konsultasi;
  final bool isAdminView;

  const KonsultasiDetailScreen({
    super.key,
    required this.konsultasi,
    this.isAdminView = false,
  });

  @override
  ConsumerState<KonsultasiDetailScreen> createState() =>
      _KonsultasiDetailScreenState();
}

class _KonsultasiDetailScreenState
    extends ConsumerState<KonsultasiDetailScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).currentUser;
    final isUserAdmin = widget.isAdminView ||
        (user?.role.toLowerCase() == 'admin' || user?.role.toLowerCase() == 'superadmin');

    _replyController.clear();
    FocusScope.of(context).unfocus();

    await ref.read(konsultasiProvider.notifier).kirimBalasan(
          konsultasiId: widget.konsultasi.id,
          userId: user?.id ?? 1,
          namaPengirim: user?.name ?? (isUserAdmin ? 'Admin Diskominfo' : 'Anda'),
          pesan: text,
          isAdmin: isUserAdmin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTeal = AppColors.primaryTeal(context);
    final actionEmerald = AppColors.actionEmerald(context);
    final strokeColor = AppColors.cardStroke(context);
    final mutedText = AppColors.mutedText(context);

    final state = ref.watch(konsultasiProvider);
    // Ambil data tiket terbaru dari state jika ada, atau fallback ke widget.konsultasi
    final currentTiket = state.listKonsultasi.firstWhere(
      (k) => k.id == widget.konsultasi.id,
      orElse: () => widget.konsultasi,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket #${currentTiket.id}'),
        centerTitle: true,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------------------------------------------------
                    // Header Card Tiket Konsultasi
                    // ---------------------------------------------------------
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentTiket.topik?['nama'] ?? 'Topik TIK',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                status: currentTiket.status,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentTiket.judul,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 14, color: mutedText),
                              const SizedBox(width: 4),
                              Text(
                                '${currentTiket.createdAt.day}/${currentTiket.createdAt.month}/${currentTiket.createdAt.year}',
                                style:
                                    TextStyle(fontSize: 12, color: mutedText),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),

                          // Initial Question / Thread Starter
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: primaryTeal,
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pesan Awal Pengajuan:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTeal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      currentTiket.pesan,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider Section Thread Balasan
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'THREAD BALASAN KONSULTASI (${currentTiket.responses.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: mutedText,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ---------------------------------------------------------
                    // List Thread Balasan Chat Bubbles (User vs Admin)
                    // ---------------------------------------------------------
                    if (currentTiket.responses.isEmpty) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(Icons.mark_chat_unread_outlined,
                                  size: 40, color: mutedText.withValues(alpha: 0.5)),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada tanggapan. Silakan tuliskan pesan balasan di bawah.',
                                style: TextStyle(
                                    fontSize: 12, color: mutedText),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...currentTiket.responses.map((resp) {
                        return _buildChatBubble(
                          context: context,
                          response: resp,
                          primaryTeal: primaryTeal,
                          strokeColor: strokeColor,
                          mutedText: mutedText,
                          theme: theme,
                          isDark: isDark,
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // Bottom Reply Input Box
            // -----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: strokeColor, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tulis balasan pesan...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: strokeColor, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: strokeColor, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: primaryTeal, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _handleSendReply,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: actionEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Builder Chat Bubble dengan posisi, warna, & radius asimetris
  Widget _buildChatBubble({
    required BuildContext context,
    required KonsultasiResponseModel response,
    required Color primaryTeal,
    required Color strokeColor,
    required Color mutedText,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isAdmin = response.isAdminUser;

    // Position Alignment: Admin di Kiri, User di Kanan
    final alignment =
        isAdmin ? Alignment.centerLeft : Alignment.centerRight;

    // Asymmetrical Border Radius: Sudut dekat pengirim lebih kecil (4px)
    final borderRadius = isAdmin
        ? const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    // Color Styling: User = primaryTeal solid, Admin = cardStroke border tanpa shadow
    final bgColor = isAdmin
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : primaryTeal;

    final textColor = isAdmin
        ? theme.colorScheme.onSurface
        : Colors.white;

    final border = isAdmin
        ? Border.all(color: strokeColor, width: 1.5)
        : null;

    final formattedTime =
        '${response.createdAt.hour.toString().padLeft(2, '0')}:${response.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: border,
          ),
          child: Column(
            crossAxisAlignment:
                isAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              // Header Pengirim (Nama & Role)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAdmin ? Icons.support_agent_rounded : Icons.person_rounded,
                    size: 14,
                    color: isAdmin ? primaryTeal : Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    response.namaPengirim ?? (isAdmin ? 'Petugas TIK' : 'Anda'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? primaryTeal : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 10,
                      color: isAdmin
                          ? mutedText
                          : Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Isi Pesan Chat Bubble
              Text(
                response.pesan,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
