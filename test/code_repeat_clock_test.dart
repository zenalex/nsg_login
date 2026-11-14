import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_login/code_repeat_clock.dart';

void main() {
  test('formats a cooldown as MM:SS', () {
    expect(formatCodeRepeatClock(90), '01:30');
    expect(formatCodeRepeatClock(1800), '30:00');
    expect(formatCodeRepeatClock(59.9), '00:59');
    expect(formatCodeRepeatClock(0), '00:00');
  });
}
