import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/privacy/privacy_controller.dart';
import 'package:sora_thu_chi/core/utilities/utilities.dart';

import 'fakes/fake_utilities_store.dart';

void main() {
  group('PrivacyController — nguồn chân lý Privacy mode (PBI 48)', () {
    test('load() phản chiếu đúng UtilitiesStore, revealed mặc định false', () async {
      final fake = FakeUtilitiesStore(
        storedPrefs: const UtilitiesPrefs(
          hideBalance: true,
          amountCalculatorEnabled: false,
        ),
      );
      final controller = PrivacyController(fake);

      await controller.load();

      expect(controller.hideBalance.value, isTrue);
      expect(controller.amountCalculatorEnabled.value, isFalse);
      expect(controller.revealed.value, isFalse);
    });

    test('setHideBalance ghi qua store, giữ nguyên amountCalculatorEnabled', () async {
      final fake = FakeUtilitiesStore(
        storedPrefs: const UtilitiesPrefs(amountCalculatorEnabled: true),
      );
      final controller = PrivacyController(fake);
      await controller.load();

      controller.setHideBalance(true);
      await Future<void>.delayed(Duration.zero);

      expect(controller.hideBalance.value, isTrue);
      expect(fake.storedPrefs.hideBalance, isTrue);
      expect(fake.storedPrefs.amountCalculatorEnabled, isTrue);
    });

    test('setAmountCalculatorEnabled ghi qua store, giữ nguyên hideBalance', () async {
      final fake = FakeUtilitiesStore(
        storedPrefs: const UtilitiesPrefs(hideBalance: true),
      );
      final controller = PrivacyController(fake);
      await controller.load();

      controller.setAmountCalculatorEnabled(false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.amountCalculatorEnabled.value, isFalse);
      expect(fake.storedPrefs.hideBalance, isTrue);
      expect(fake.storedPrefs.amountCalculatorEnabled, isFalse);
    });

    test('setHideBalance(false) reset revealed về false', () async {
      final fake = FakeUtilitiesStore(
        storedPrefs: const UtilitiesPrefs(hideBalance: true),
      );
      final controller = PrivacyController(fake);
      await controller.load();
      controller.revealed.value = true;

      controller.setHideBalance(false);

      expect(controller.revealed.value, isFalse);
    });
  });
}
