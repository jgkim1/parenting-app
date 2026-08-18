import 'package:flutter_test/flutter_test.dart';
import 'package:parenting_app/core/utils/formatters.dart';

void main() {
  group('formatPriceKrw', () {
    test('세 자리 미만 숫자는 그대로 표시한다', () {
      expect(formatPriceKrw(0), '0');
      expect(formatPriceKrw(5), '5');
      expect(formatPriceKrw(999), '999');
    });

    test('천 단위마다 콤마를 찍는다', () {
      expect(formatPriceKrw(1000), '1,000');
      expect(formatPriceKrw(15900), '15,900');
      expect(formatPriceKrw(189000), '189,000');
      expect(formatPriceKrw(1234567), '1,234,567');
    });
  });
}
