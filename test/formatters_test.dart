import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_booking/utils/formatters.dart';

void main() {
  test('relativeDay labels today and tomorrow', () {
    final base = DateTime(2026, 9, 18);

    expect(Formatters.relativeDay(base, from: base), 'Today');
    expect(
      Formatters.relativeDay(base.add(const Duration(days: 1)), from: base),
      'Tomorrow',
    );
    expect(
      Formatters.relativeDay(base.subtract(const Duration(days: 1)), from: base),
      'Yesterday',
    );
  });
}
