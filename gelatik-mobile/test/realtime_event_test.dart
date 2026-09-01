import 'package:flutter_test/flutter_test.dart';
import 'package:gelatik/core/realtime/realtime_event.dart';

void main() {
  test(
    'email create and verification events use the shared realtime contract',
    () {
      final created = RealtimeEvent.tryParse('usulan_email.created', const {
        'event_id': 'email-created-0001',
        'type': 'usulan_email.created',
        'entity_id': 31,
        'status': 'Diajukan',
        'created_at': '2026-09-01T01:00:00.000Z',
      });
      final verified = RealtimeEvent.tryParse('usulan_email.verified', const {
        'event_id': 'email-verified-0001',
        'type': 'usulan_email.verified',
        'entity_id': 31,
        'verification_state': 'verified',
        'created_at': '2026-09-01T01:01:00.000Z',
      });

      expect(created?.entityId, 31);
      expect(created?.status, 'Diajukan');
      expect(verified?.entityId, 31);
      expect(verified?.type, 'usulan_email.verified');
    },
  );
}
