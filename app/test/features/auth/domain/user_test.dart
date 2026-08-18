import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/auth/domain/user.dart';

void main() {
  group('AppUser.fromJson', () {
    test('필드를 그대로 매핑한다', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'email': 'test@example.com',
        'nickname': '테스터',
        'role': 'CUSTOMER',
      });

      expect(user.id, 'u1');
      expect(user.email, 'test@example.com');
      expect(user.nickname, '테스터');
      expect(user.role, 'CUSTOMER');
    });
  });
}
