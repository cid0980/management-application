import 'package:flutter_test/flutter_test.dart';
import 'package:fm_shop/ui/widgets/shop_ui.dart';

void main() {
  test('each group once, most common first, blanks left out', () {
    expect(
      groupsByCount(['Oppo', 'Samsung A54', 'Oppo', '  ', 'Apple', 'Oppo ']),
      ['Oppo', 'Apple', 'Samsung A54'],
    );
  });
}
