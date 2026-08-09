import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/features/auth/models/user_model.dart';

void main() {
  test(
    'parses /me role relation and nullable legacy profile fields safely',
    () {
      final user = UserModel.fromJson({
        'id': '7',
        'name': 'Pengguna Uji',
        'email': null,
        'username': 'pengguna.uji',
        'no_hp': null,
        'nama_opd': null,
        'roles': [
          {'name': 'admin'},
        ],
        'status': 1,
      });

      expect(user.id, 7);
      expect(user.role, 'admin');
      expect(user.email, isEmpty);
      expect(user.noHp, isEmpty);
      expect(user.namaOpd, isEmpty);
      expect(user.status, '1');
    },
  );
}
