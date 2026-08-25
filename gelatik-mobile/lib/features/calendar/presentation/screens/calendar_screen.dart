import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gelatik_page_header.dart';
import '../../repositories/calendar_repository.dart';

/// Mobile-native agenda. The API applies ownership for users and the broader
/// operational scope for admin/superadmin, so this widget never guesses scope.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<CalendarEvent> _events = const [];
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
    final start = _month;
    final end = DateTime(_month.year, _month.month + 1, 0);
    try {
      final events = await ref
          .read(calendarRepositoryProvider)
          .getEvents(start: start, end: end);
      if (mounted) setState(() => _events = events);
    } catch (_) {
      if (mounted) setState(() => _error = 'Agenda belum dapat dimuat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
    _load();
  }

  List<CalendarEvent> _eventsFor(DateTime day) => _events
      .where(
        (event) =>
            event.start.year == day.year &&
            event.start.month == day.month &&
            event.start.day == day.day,
      )
      .toList(growable: false);

  void _showDay(DateTime day) {
    final events = _eventsFor(day);
    if (events.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day} ${_monthNames[day.month - 1]} ${day.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...events.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconFor(event.type), color: _colorFor(context, event.type)),
                  title: Text(event.title),
                  subtitle: Text(event.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = _month.weekday - 1;
    final totalDays = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = List<DateTime?>.generate(42, (index) {
      final day = index - firstDay + 1;
      return day < 1 || day > totalDays ? null : DateTime(_month.year, _month.month, day);
    });
    final today = DateTime.now();

    return Scaffold(
      appBar: const GelatikPageHeader(title: 'Agenda Layanan', showBack: true),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            children: [
              AppCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_monthNames[_month.month - 1]} ${_month.year}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Bulan sebelumnya',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        IconButton(
                          tooltip: 'Bulan berikutnya',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        _Weekday('Sen'), _Weekday('Sel'), _Weekday('Rab'),
                        _Weekday('Kam'), _Weekday('Jum'), _Weekday('Sab'),
                        _Weekday('Min'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(_error!),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cells.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: .82,
                        ),
                        itemBuilder: (context, index) {
                          final day = cells[index];
                          if (day == null) return const SizedBox.shrink();
                          final events = _eventsFor(day);
                          final isToday = day.year == today.year &&
                              day.month == today.month &&
                              day.day == today.day;
                          return InkWell(
                            onTap: events.isEmpty ? null : () => _showDay(day),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? AppColors.accentNavy(context)
                                      : events.isEmpty
                                      ? Colors.transparent
                                      : AppColors.primaryTeal(context).withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${day.day}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isToday ? Colors.white : null,
                                        ),
                                      ),
                                      if (events.isNotEmpty) ...[
                                        const Spacer(),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? AppColors.accentGold(context)
                                                : _colorFor(context, events.first.type),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Agenda menampilkan pengajuan Anda. Admin dan superadmin melihat agenda operasional sesuai hak akses.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context, String type) => switch (type) {
    'peminjaman' => AppColors.accentNavy(context),
    'konsultasi' => AppColors.primaryTeal(context),
    'usulan_email' => AppColors.accentGold(context),
    _ => AppColors.mutedText(context),
  };

  IconData _iconFor(String type) => switch (type) {
    'peminjaman' => Icons.devices_other_outlined,
    'konsultasi' => Icons.forum_outlined,
    'usulan_email' => Icons.mark_email_read_outlined,
    _ => Icons.campaign_outlined,
  };
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );
}

const _monthNames = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
