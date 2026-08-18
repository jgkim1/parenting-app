import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/features/children/domain/child.dart';

void main() {
  group('ChildGenderApi', () {
    test('apiValue/label이 각 성별에 맞게 매핑된다', () {
      expect(ChildGender.male.apiValue, 'MALE');
      expect(ChildGender.male.label, '남아');
      expect(ChildGender.female.apiValue, 'FEMALE');
      expect(ChildGender.female.label, '여아');
      expect(ChildGender.other.apiValue, 'OTHER');
      expect(ChildGender.other.label, '기타');
    });

    test('fromApiValue는 알 수 없는 값이나 null이면 null을 반환한다', () {
      expect(ChildGenderApi.fromApiValue('MALE'), ChildGender.male);
      expect(ChildGenderApi.fromApiValue(null), isNull);
      expect(ChildGenderApi.fromApiValue('UNKNOWN'), isNull);
    });
  });

  group('Child.fromJson', () {
    test('gender가 null이어도 처리한다', () {
      final child = Child.fromJson({
        'id': 'child1',
        'nickname': '첫째',
        'gender': null,
        'birthDate': '2024-01-15T00:00:00.000Z',
      });
      expect(child.nickname, '첫째');
      expect(child.gender, isNull);
    });

    test('gender 문자열을 ChildGender로 변환한다', () {
      final child = Child.fromJson({
        'id': 'child1',
        'nickname': '둘째',
        'gender': 'FEMALE',
        'birthDate': '2024-01-15T00:00:00.000Z',
      });
      expect(child.gender, ChildGender.female);
    });
  });

  group('Child.ageInMonths', () {
    test('연/월 차이로 개월수를 계산한다', () {
      final now = DateTime.now();
      final oneYearAgo = DateTime(now.year - 1, now.month, 1);
      final child = Child(id: 'c1', nickname: '아이', gender: null, birthDate: oneYearAgo);
      expect(child.ageInMonths, 12);
    });

    test('같은 달에 태어났으면 0개월이다', () {
      final now = DateTime.now();
      final child = Child(id: 'c1', nickname: '아이', gender: null, birthDate: DateTime(now.year, now.month, 1));
      expect(child.ageInMonths, 0);
    });
  });
}
