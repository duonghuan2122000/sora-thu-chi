import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/app_shell.dart';
import 'package:sora_thu_chi/data/privacy_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';

import 'fakes/fake_wallet_repository.dart';

void main() {
  group('AppShell — reset Privacy mode "xem tạm thời" khi rời tab Tổng quan (PBI 48)', () {
    testWidgets('Rời tab Tổng quan (chọn tab khác) → revealed reset về false', (
      tester,
    ) async {
      Get.reset();
      Get.put<WalletRepository>(FakeWalletRepository(null));
      addTearDown(Get.reset);

      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.pumpAndSettle();

      final privacy = ensurePrivacyController();
      privacy.revealed.value = true;

      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      expect(privacy.revealed.value, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
