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
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(konsultasiProvider.notifier)
          .loadDetail(widget.konsultasi.id),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  bool _isAdmin(String? role) {
    final normalized = role?.toLowerCase();
    return normalized == 'admin' || normalized == 'superadmin';
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final success = await ref
        .read(konsultasiProvider.notifier)
        .kirimBalasan(konsultasiId: widget.konsultasi.id, isiRespon: text);
    if (!mounted) return;
    if (success) {
      _replyController.clear();
      FocusScope.of(context).unfocus();
    } else {
      final message = ref.read(konsultasiProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Gagal mengirim balasan.')),
      );
    }
  }

  Future<void> _changeStatus(String status) async {
    final success = await ref
        .read(konsultasiProvider.notifier)
        .ubahStatus(widget.konsultasi.id, status);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(konsultasiProvider).errorMessage ??
              'Gagal memperbarui status.',
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus konsultasi?'),
        content: const Text('Konsultasi yang dihapus tidak dapat dipulihkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(konsultasiProvider.notifier)
        .hapusKonsultasi(widget.konsultasi.id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(konsultasiProvider).errorMessage ??
                'Gagal menghapus konsultasi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(konsultasiProvider);
    final user = ref.watch(authProvider).currentUser;
    final current = state.selectedKonsultasi?.id == widget.konsultasi.id
        ? state.selectedKonsultasi!
        : widget.konsultasi;
    final hasCurrentDetail =
        state.selectedKonsultasi?.id == widget.konsultasi.id;
    // The route context may adjust presentation, but only authenticated role
    // state may grant privileged mutation controls.
    final isAdmin = _isAdmin(user?.role);
    final isOwner = user != null && user.id == current.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tiket #${current.id}'),
        centerTitle: true,
        actions: [
          if (isOwner && !isAdmin)
            IconButton(
              key: const Key('delete-consultation'),
              onPressed: state.isSubmitting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: state.status == KonsultasiLoadStatus.loading && !hasCurrentDetail
            ? const Center(child: CircularProgressIndicator())
            : state.status == KonsultasiLoadStatus.error && !hasCurrentDetail
            ? _DetailError(
                message: state.errorMessage ?? 'Gagal memuat detail.',
                onRetry: () => ref
                    .read(konsultasiProvider.notifier)
                    .loadDetail(widget.konsultasi.id),
              )
            : Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref
                          .read(konsultasiProvider.notifier)
                          .loadDetail(widget.konsultasi.id),
                      child: ListView(
                        key: const Key('consultation-detail'),
                        padding: const EdgeInsets.all(16),
                        children: [
                          _HeaderCard(konsultasi: current),
                          if (isAdmin) ...[
                            const SizedBox(height: 12),
                            _StatusActions(
                              currentStatus: current.status,
                              isSubmitting: state.isSubmitting,
                              onChange: _changeStatus,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Balasan (${current.responses.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          if (current.responses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Belum ada tanggapan.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...current.responses.map(
                              (response) => _ResponseBubble(
                                response: response,
                                isAdminResponse:
                                    response.userId != current.userId,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _ReplyBox(
                    controller: _replyController,
                    submitting: state.isSubmitting,
                    onSend: _sendReply,
                  ),
                ],
              ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final KonsultasiModel konsultasi;

  const _HeaderCard({required this.konsultasi});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(konsultasi.topikNama)),
            StatusBadge(status: konsultasi.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          konsultasi.judul,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${konsultasi.createdAt.day}/${konsultasi.createdAt.month}/${konsultasi.createdAt.year}',
          style: TextStyle(color: AppColors.mutedText(context)),
        ),
        const Divider(height: 24),
        Text(konsultasi.pesan),
        if (konsultasi.file != null) ...[
          const SizedBox(height: 10),
          Text('Lampiran: ${konsultasi.file}'),
        ],
      ],
    ),
  );
}

class _StatusActions extends StatelessWidget {
  final String currentStatus;
  final bool isSubmitting;
  final ValueChanged<String> onChange;

  const _StatusActions({
    required this.currentStatus,
    required this.isSubmitting,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final actions = switch (currentStatus) {
      'Menunggu' => const ['Diproses', 'Ditolak', 'Selesai'],
      'Diproses' => const ['Ditolak', 'Selesai'],
      _ => const <String>[],
    };
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      key: const Key('admin-status-actions'),
      spacing: 8,
      children: actions
          .map(
            (status) => OutlinedButton(
              onPressed: isSubmitting ? null : () => onChange(status),
              child: Text(status),
            ),
          )
          .toList(),
    );
  }
}

class _ResponseBubble extends StatelessWidget {
  final KonsultasiResponseModel response;
  final bool isAdminResponse;

  const _ResponseBubble({
    required this.response,
    required this.isAdminResponse,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: isAdminResponse ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * .82,
      ),
      decoration: BoxDecoration(
        color: isAdminResponse
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : AppColors.primaryTeal(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response.userName ?? (isAdminResponse ? 'Admin TIK' : 'Anda'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAdminResponse ? null : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            response.pesan,
            style: TextStyle(color: isAdminResponse ? null : Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _ReplyBox extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSend;

  const _ReplyBox({
    required this.controller,
    required this.submitting,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('reply-field'),
            controller: controller,
            enabled: !submitting,
            decoration: const InputDecoration(
              hintText: 'Tulis balasan pesan...',
            ),
          ),
        ),
        IconButton(
          key: const Key('send-reply'),
          onPressed: submitting ? null : onSend,
          icon: submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
        ),
      ],
    ),
  );
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Coba Lagi')),
      ],
    ),
  );
}
