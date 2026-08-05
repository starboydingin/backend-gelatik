class KonsultasiTopikModel {
  final int id;
  final String nama;
  final String? status;

  const KonsultasiTopikModel({
    required this.id,
    required this.nama,
    this.status,
  });

  factory KonsultasiTopikModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final nama = json['topik'];
    if (id == null || nama is! String || nama.isEmpty) {
      throw const FormatException('Data topik konsultasi tidak valid.');
    }
    return KonsultasiTopikModel(
      id: id,
      nama: nama,
      status: json['status']?.toString(),
    );
  }
}
