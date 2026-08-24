import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../internet/utils/faq_html_formatter.dart';
import '../../models/konsultasi_topik_model.dart';
import '../../providers/konsultasi_provider.dart';
import '../../repositories/konsultasi_repository.dart';
import 'buat_konsultasi_screen.dart';

class KonsultasiDiscoveryScreen extends ConsumerStatefulWidget {
  const KonsultasiDiscoveryScreen({super.key});

  @override
  ConsumerState<KonsultasiDiscoveryScreen> createState() =>
      _KonsultasiDiscoveryScreenState();
}

class _KonsultasiDiscoveryScreenState
    extends ConsumerState<KonsultasiDiscoveryScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _faqs = const [];
  int? _selectedTopikId;
  bool _loadingFaq = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await ref.read(konsultasiProvider.notifier).loadTopik();
    try {
      final faqs = await ref.read(konsultasiRepositoryProvider).getFaq();
      if (mounted) setState(() => _faqs = faqs);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingFaq = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _faqTopikId(Map<String, dynamic> faq) {
    final value = faq['topik_id'];
    return value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  List<Map<String, dynamic>> get _visibleFaqs {
    final query = _searchController.text.trim().toLowerCase();
    return _faqs
        .where((faq) {
          if (_selectedTopikId != null &&
              _faqTopikId(faq) != _selectedTopikId) {
            return false;
          }
          if (query.isEmpty) return true;
          final text = '${faq['judul'] ?? ''} ${faq['detail'] ?? ''}'
              .toLowerCase();
          return text.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _continue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BuatKonsultasiScreen(initialTopikId: _selectedTopikId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topiks = ref
        .watch(konsultasiProvider)
        .topiks
        .where((topik) => topik.status == null || topik.status == '1')
        .toList(growable: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Topik & FAQ Konsultasi')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Temukan jawaban sebelum mengajukan',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal(context),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih topik dan baca FAQ yang relevan. Anda tetap dapat melanjutkan ke formulir konsultasi.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Cari topik atau FAQ',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 14),
            _TopicSelector(
              topiks: topiks,
              selectedId: _selectedTopikId,
              onSelected: (id) => setState(() => _selectedTopikId = id),
            ),
            const SizedBox(height: 18),
            if (_loadingFaq)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              AppCard(
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (_visibleFaqs.isEmpty)
              const AppCard(
                child: Text('Belum ada FAQ yang cocok dengan pilihan Anda.'),
              )
            else
              ..._visibleFaqs.map(
                (faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      title: Text(
                        faq['judul']?.toString() ?? 'FAQ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faqHtmlToPlainText(faq['detail']?.toString() ?? ''),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppButton(
              text: 'Lanjut ke Form Konsultasi',
              icon: Icons.arrow_forward_rounded,
              backgroundColor: AppColors.actionEmerald(context),
              textColor: Colors.white,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicSelector extends StatelessWidget {
  final List<KonsultasiTopikModel> topiks;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  const _TopicSelector({
    required this.topiks,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      ChoiceChip(
        label: const Text('Semua'),
        selected: selectedId == null,
        onSelected: (_) => onSelected(null),
      ),
      ...topiks.map(
        (topik) => ChoiceChip(
          label: Text(topik.nama),
          selected: selectedId == topik.id,
          onSelected: (_) => onSelected(topik.id),
        ),
      ),
    ],
  );
}
