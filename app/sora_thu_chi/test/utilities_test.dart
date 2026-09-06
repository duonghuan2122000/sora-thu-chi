import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/utilities/utilities.dart';

void main() {
  group('UtilitiesPrefs — domain thuần', () {
    test('mặc định: Ẩn số dư tắt, Máy tính bật (mockup)', () {
      const prefs = UtilitiesPrefs();
      expect(prefs.hideBalance, isFalse);
      expect(prefs.amountCalculatorEnabled, isTrue);
    });

    test('toSettings → đủ 2 khóa, bool lưu chuỗi true/false', () {
      const prefs = UtilitiesPrefs();
      final settings = prefs.toSettings();
      expect(settings, {
        kKeyHideBalance: 'false',
        kKeyAmountCalculatorEnabled: 'true',
      });
    });

    test('fromSettings rỗng → giữ mặc định', () {
      final prefs = UtilitiesPrefs.fromSettings(const {});
      expect(prefs.hideBalance, isFalse);
      expect(prefs.amountCalculatorEnabled, isTrue);
    });

    test('fromSettings đủ 2 row → parse đúng', () {
      final prefs = UtilitiesPrefs.fromSettings(const {
        kKeyHideBalance: 'true',
        kKeyAmountCalculatorEnabled: 'false',
      });
      expect(prefs.hideBalance, isTrue);
      expect(prefs.amountCalculatorEnabled, isFalse);
    });

    test('fromSettings thiếu 1 trong 2 key → giữ mặc định phần vắng', () {
      final onlyHide = UtilitiesPrefs.fromSettings(const {
        kKeyHideBalance: 'true',
      });
      expect(onlyHide.hideBalance, isTrue);
      expect(onlyHide.amountCalculatorEnabled, isTrue); // key vắng → mặc định

      final onlyCalc = UtilitiesPrefs.fromSettings(const {
        kKeyAmountCalculatorEnabled: 'false',
      });
      expect(onlyCalc.hideBalance, isFalse); // key vắng → mặc định
      expect(onlyCalc.amountCalculatorEnabled, isFalse);
    });

    test('fromSettings chuỗi không parse được → mặc định, không ném', () {
      for (final bad in ['yes', '', 'TRUE', 'True', '1', 'tru']) {
        final prefs = UtilitiesPrefs.fromSettings({
          kKeyHideBalance: bad,
          kKeyAmountCalculatorEnabled: bad,
        });
        expect(prefs.hideBalance, isFalse,
            reason: 'hideBalance "$bad" → mặc định false');
        expect(prefs.amountCalculatorEnabled, isTrue,
            reason: 'amountCalculatorEnabled "$bad" → mặc định true');
      }
    });

    test('copyWith đổi từng field, giữ field kia', () {
      const prefs = UtilitiesPrefs();
      final hid = prefs.copyWith(hideBalance: true);
      expect(hid.hideBalance, isTrue);
      expect(hid.amountCalculatorEnabled, isTrue); // giữ nguyên

      final calc = prefs.copyWith(amountCalculatorEnabled: false);
      expect(calc.hideBalance, isFalse); // giữ nguyên
      expect(calc.amountCalculatorEnabled, isFalse);
    });

    test('round-trip fromSettings(toSettings) = giá trị', () {
      const toggled = UtilitiesPrefs(hideBalance: true, amountCalculatorEnabled: false);
      final back = UtilitiesPrefs.fromSettings(toggled.toSettings());
      expect(back.hideBalance, isTrue);
      expect(back.amountCalculatorEnabled, isFalse);
    });
  });
}
