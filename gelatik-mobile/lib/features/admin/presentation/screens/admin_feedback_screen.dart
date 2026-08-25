import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../../kritik_saran/repositories/kritik_saran_repository.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final items = await ref.read(kritikSaranRepositoryProvider).getAdminFeedback();
      if (mounted) setState(() { _items = items; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reply(Map<String, dynamic> item) async {
    final controller = TextEditingController(text: item['balasan']?.toString() ?? '');
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balas kritik & saran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller,
              labelText: 'Tanggapan untuk pengguna',
              hintText: 'Tulis balasan yang jelas dan membantu…',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Kirim balasan',
              onPressed: () async {
                final reply = controller.text.trim();
                if (reply.isEmpty) return;
                await ref.read(kritikSaranRepositoryProvider).reply(
                  id: int.tryParse('${item['id']}') ?? 0,
                  balasan: reply,
                );
                if (sheetContext.mounted) Navigator.pop(sheetContext, true);
              },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (submitted == true) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const GelatikPageHeader(title: 'Kritik & Saran', showBack: true),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(children: [Padding(padding: const EdgeInsets.all(20), child: Text(_error!))])
          : _items.isEmpty
          ? const Center(child: Text('Belum ada masukan pengguna.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final user = item['user'] is Map ? item['user'] as Map : const {};
                final repliedAt = DateTime.tryParse('${item['dibalas_pada'] ?? ''}');
                final createdAt = DateTime.tryParse('${item['created_at'] ?? ''}');
                return AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${user['name'] ?? 'Anonim'}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (createdAt != null) Text(GelatikDateFormatter.dateTime(createdAt), style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                    const SizedBox(height: 12),
                    Text('Kritik: ${item['kritik'] ?? '-'}'),
                    const SizedBox(height: 6),
                    Text('Saran: ${item['saran'] ?? '-'}'),
                    if (item['balasan'] != null) ...[
                      const SizedBox(height: 14),
                      Text('Balasan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryTeal(context))),
                      const SizedBox(height: 4),
                      Text('${item['balasan']}'),
                      if (repliedAt != null) Text(GelatikDateFormatter.dateTime(repliedAt), style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
                    ],
                    const SizedBox(height: 14),
                    Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _reply(item), child: Text(item['balasan'] == null ? 'Balas' : 'Perbarui balasan'))),
                  ]),
                );
              },
            ),
    ),
  );
}
