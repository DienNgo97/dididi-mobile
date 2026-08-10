import 'package:flutter_test/flutter_test.dart';

import 'package:dididi_mobile/shared/format.dart';

void main() {
  test('formatVnd: định dạng tiền VND + rỗng', () {
    expect(formatVnd(null), '—');
    expect(formatVnd(1000).endsWith('đ'), true);
  });

  test('ago: mốc thời gian rỗng trả chuỗi rỗng', () {
    expect(ago(0), '');
  });
}
