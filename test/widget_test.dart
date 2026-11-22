import 'package:flutter_test/flutter_test.dart';
void main() {
  test('weight based price calculation rounds to rial', () {
    expect((1500 * 6500 / 1000).round(), 9750);
    expect((250 * 12000 / 1000).round(), 3000);
  });
  test('empty values fail integer parsing', () {
    expect(int.tryParse(''), isNull);
  });
}
