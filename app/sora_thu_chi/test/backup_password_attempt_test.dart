import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/backup/backup_password_attempt.dart';

void main() {
  test('lần đầu chưa từng sai → độ trễ 0', () {
    final delay = BackupPasswordAttemptDelay();
    expect(delay.nextDelay, Duration.zero);
  });

  test('mỗi lần sai liên tiếp tăng gấp đôi, có trần', () {
    final delay = BackupPasswordAttemptDelay(
      base: const Duration(milliseconds: 100),
      cap: const Duration(milliseconds: 350),
    );
    delay.recordFailure();
    expect(delay.nextDelay, const Duration(milliseconds: 100));
    delay.recordFailure();
    expect(delay.nextDelay, const Duration(milliseconds: 200));
    delay.recordFailure();
    expect(delay.nextDelay, const Duration(milliseconds: 350), reason: 'bị chặn ở trần 350ms (lẽ ra 400ms)');
    delay.recordFailure();
    expect(delay.nextDelay, const Duration(milliseconds: 350));
  });

  test('reset về 0 sau lần đúng', () {
    final delay = BackupPasswordAttemptDelay();
    delay.recordFailure();
    delay.recordFailure();
    expect(delay.nextDelay, isNot(Duration.zero));
    delay.recordSuccess();
    expect(delay.nextDelay, Duration.zero);
  });
}
