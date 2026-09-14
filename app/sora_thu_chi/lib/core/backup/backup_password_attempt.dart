/// Độ trễ tăng dần chống dò mật khẩu file backup (T037, doc §5): mỗi lần sai
/// liên tiếp tăng gấp đôi, có trần; đúng → reset về 0. Thuần đếm — nơi gọi tự
/// `await Future.delayed(delay)` trước khi cho nhập lại.
class BackupPasswordAttemptDelay {
  BackupPasswordAttemptDelay({
    this.base = const Duration(milliseconds: 500),
    this.cap = const Duration(seconds: 8),
  });

  final Duration base;
  final Duration cap;
  int _consecutiveFailures = 0;

  /// Độ trễ áp dụng cho lần thử **tiếp theo** — `0` lần sai trước đó → 0ms
  /// (thử đầu tiên không chờ); tăng gấp đôi mỗi lần sai, không vượt [cap].
  Duration get nextDelay {
    if (_consecutiveFailures == 0) return Duration.zero;
    final millis =
        base.inMilliseconds * (1 << (_consecutiveFailures - 1));
    final capped = millis > cap.inMilliseconds ? cap.inMilliseconds : millis;
    return Duration(milliseconds: capped);
  }

  void recordFailure() => _consecutiveFailures++;

  void recordSuccess() => _consecutiveFailures = 0;
}
