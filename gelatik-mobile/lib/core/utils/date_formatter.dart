class GelatikDateFormatter {
  static const _months = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String date(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')} '
        '${_months[local.month - 1]} ${local.year}';
  }

  static String dateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${date(local)}, $hour:$minute';
  }
}
