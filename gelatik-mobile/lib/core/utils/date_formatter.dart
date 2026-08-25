class GelatikDateFormatter {
  static const _wibOffset = Duration(hours: 7);
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
    final jakarta = _jakarta(value);
    return '${jakarta.day} ${_months[jakarta.month - 1]} ${jakarta.year}';
  }

  static String dateTime(DateTime value) {
    final jakarta = _jakarta(value);
    final hour = jakarta.hour.toString().padLeft(2, '0');
    final minute = jakarta.minute.toString().padLeft(2, '0');
    return '${jakarta.day} ${_months[jakarta.month - 1]} ${jakarta.year}, '
        '$hour.$minute WIB';
  }

  /// API mengirim timestamp UTC. Konversi dari UTC secara eksplisit agar
  /// hasilnya selalu WIB/Jakarta, terlepas dari zona waktu perangkat.
  static DateTime _jakarta(DateTime value) => value.toUtc().add(_wibOffset);
}
