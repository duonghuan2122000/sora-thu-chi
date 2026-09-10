import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/locale_controller.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/screens/language_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_locale_store.dart';

/// `Get.locale` là biến toàn cục của GetX → phải khôi phục trong teardown, nếu
/// không sẽ rò rỉ sang test sau trong cùng file (plan §Rủi ro 3).
LocaleController registerLocale({Locale? initialLocale}) {
  Get.reset();
  Get.locale = null;
  final ctl = LocaleController(FakeLocaleStore(initialLocale: initialLocale));
  Get.put<LocaleController>(ctl);
  addTearDown(() {
    Get.reset();
    Get.locale = null;
  });
  return ctl;
}

Widget buildApp(LocaleController ctl, {Widget? home}) {
  return Obx(
    () => GetMaterialApp(
      theme: AppTheme.themeData,
      translations: SoraTranslations(),
      locale: ctl.locale.value,
      home: home ?? const Scaffold(body: SizedBox.expand()),
    ),
  );
}

/// `setLocale` gọi `Get.updateLocale` → `reassembleApplication()` (warm-up
/// frame). Trong test binding, chuỗi async này phải chạy ở zone thật rồi mới
/// pump, nếu không `handleBeginFrame` vỡ assert `schedulerPhase == idle`.
/// KHÔNG `await` kết quả `Get.updateLocale` (plan §Rủi ro 4).
Future<void> settleLocaleChange(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Màn "khác" đang mở dưới — nhãn dựng trong `build` nên theo ngôn ngữ mới sau
/// khi reassemble (FR-005).
class _OtherScreen extends StatelessWidget {
  const _OtherScreen();

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Giao dịch'.tr)));
}

bool radioSelected(WidgetTester tester, String code) {
  final card = find.byKey(ValueKey('language-option-$code'));
  return find
      .descendant(of: card, matching: find.byIcon(Icons.check))
      .evaluate()
      .isNotEmpty;
}

/// Mở màn 03 qua route (có nút back như app thật).
Future<void> openLanguage(WidgetTester tester, LocaleController ctl) async {
  await tester.pumpWidget(buildApp(ctl));
  await tester.pumpAndSettle();
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => LanguageScreen(controller: ctl)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('(a) Bố cục mockup 03: back + tiêu đề, 2 hàng đúng thứ tự, ghi chú',
      (tester) async {
    final ctl = registerLocale();
    await openLanguage(tester, ctl);

    // App bar: back + tiêu đề; không bottom nav (FR-001).
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // Đúng 2 hàng: mã + tên + dòng phụ đúng mockup.
    expect(find.text('VI'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('Vietnamese'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tiếng Anh'), findsOneWidget);

    // Thứ tự Tiếng Việt → English (FR-002).
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('language-option-vi'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('language-option-en'))).dy,
      ),
    );

    // Ghi chú chân màn.
    expect(find.textContaining('Áp dụng ngay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('(b) Mặc định: radio Tiếng Việt chọn sẵn, English không chọn (FR-004)',
      (tester) async {
    final ctl = registerLocale();
    await openLanguage(tester, ctl);

    expect(radioSelected(tester, 'vi'), isTrue);
    expect(radioSelected(tester, 'en'), isFalse);
  });

  testWidgets('(c) Chạm English → radio đổi + Get.locale = en + ghi store + tiêu đề đổi ngay',
      (tester) async {
    final ctl = registerLocale();
    await openLanguage(tester, ctl);

    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await settleLocaleChange(tester);

    expect(radioSelected(tester, 'en'), isTrue);
    expect(radioSelected(tester, 'vi'), isFalse);
    expect(Get.locale?.languageCode, 'en');
    expect(ctl.locale.value, const Locale('en'));

    // Tiêu đề app bar của chính màn này đổi ngay, không khởi động lại (FR-005).
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsNothing);
  });

  testWidgets('(d) Route khác cũng đổi nhãn theo, không cần mở lại app (FR-005)',
      (tester) async {
    final ctl = registerLocale();
    await tester.pumpWidget(buildApp(ctl, home: const _OtherScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Giao dịch'), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => LanguageScreen(controller: ctl)),
    );
    await tester.pumpAndSettle();

    ctl.setLocale(const Locale('en'));
    await settleLocaleChange(tester);

    navigator.pop();
    await tester.pumpAndSettle();

    // Nhãn route dưới đã theo ngôn ngữ mới.
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Giao dịch'), findsNothing);
  });

  testWidgets('(e) Mở lại app với lựa chọn đã lưu → radio English chọn sẵn (FR-006)',
      (tester) async {
    final ctl = registerLocale(initialLocale: const Locale('en'));
    await ctl.load();
    await openLanguage(tester, ctl);

    expect(radioSelected(tester, 'en'), isTrue);
    expect(radioSelected(tester, 'vi'), isFalse);
  });

  testWidgets('(f) Chạm nhanh liên tiếp English → Tiếng Việt → English: lần cuối thắng',
      (tester) async {
    final ctl = registerLocale();
    await openLanguage(tester, ctl);

    // Mỗi lần đổi phải để reassemble chạy xong trước khi chạm tiếp (cây widget
    // đang dirty thì không hit-test được).
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await settleLocaleChange(tester);
    await tester.tap(find.byKey(const ValueKey('language-option-vi')));
    await settleLocaleChange(tester);
    await tester.tap(find.byKey(const ValueKey('language-option-en')));
    await settleLocaleChange(tester);

    expect(ctl.locale.value, const Locale('en'));
    expect(radioSelected(tester, 'en'), isTrue);
  });

  testWidgets('(g) Chạm lại hàng đang chọn → no-op', (tester) async {
    final ctl = registerLocale();
    await openLanguage(tester, ctl);

    await tester.tap(find.byKey(const ValueKey('language-option-vi')));
    await tester.pump();

    expect(ctl.locale.value, const Locale('vi'));
    expect(radioSelected(tester, 'vi'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('(h) Cỡ chữ lớn + màn nhỏ: cuộn tới ghi chú, không overflow (FR-013)',
      (tester) async {
    final ctl = registerLocale();
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await openLanguage(tester, ctl);

    await tester.dragUntilVisible(
      find.textContaining('Áp dụng ngay'),
      find.byType(Scrollable).first,
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Áp dụng ngay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
