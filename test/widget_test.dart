import 'package:flutter_test/flutter_test.dart';

import 'package:moneytrackerpro/app/app.dart';

void main() {
  test('MoneyTracker Pro app root can be constructed', () {
    const app = MoneyTrackerApp();

    expect(app, isA<MoneyTrackerApp>());
  });
}
