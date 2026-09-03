import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/app.dart';
import 'package:sora_thu_chi/core/widgets/app_bottom_nav_bar.dart';
import 'package:sora_thu_chi/core/widgets/screen_header.dart';

void main() {
  group('AppShell — điều hướng 4 vùng chính', () {
    testWidgets('Boot vào Tổng quan, đủ 4 tab + ô giữa', (tester) async {
      await tester.pumpWidget(const SoraApp());

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byType(ScreenHeader), findsOneWidget);
      // Header đang hiện + nhãn tab → 2 chỗ có chữ "Tổng quan".
      expect(find.text('Tổng quan'), findsNWidgets(2));
      // Các tab khác mới chỉ xuất hiện ở nhãn (header của chúng đang offstage).
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Báo cáo'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Tap từng tab → màn chính đổi tương ứng', (tester) async {
      await tester.pumpWidget(const SoraApp());

      Future<void> tapTab(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tapTab('Giao dịch');
      expect(find.text('Giao dịch'), findsNWidgets(2)); // header + tab

      await tapTab('Báo cáo');
      expect(find.text('Báo cáo'), findsNWidgets(2));

      await tapTab('Cài đặt');
      expect(find.text('Cài đặt'), findsNWidgets(2));

      await tapTab('Tổng quan');
      expect(find.text('Tổng quan'), findsNWidgets(2));
    });

    testWidgets('FAB hiện cố định trên cả 4 màn chính', (tester) async {
      await tester.pumpWidget(const SoraApp());

      for (final label in ['Giao dịch', 'Báo cáo', 'Cài đặt', 'Tổng quan']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add), findsOneWidget,
            reason: 'FAB phải hiện khi ở màn $label');
      }
    });

    testWidgets('Tap FAB → mở màn phụ, không còn bottom nav', (tester) async {
      await tester.pumpWidget(const SoraApp());

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Quay lại từ màn phụ → đúng tab cũ', (tester) async {
      await tester.pumpWidget(const SoraApp());

      // Sang tab Báo cáo rồi mở màn phụ.
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Back bằng nút app bar (BackButton) → về đúng tab Báo cáo.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Báo cáo'), findsNWidgets(2)); // header + tab còn chọn
    });

    testWidgets('FR-004: rời tab rồi quay lại → vẫn ở đúng vùng', (tester) async {
      await tester.pumpWidget(const SoraApp());

      // Sang Giao dịch.
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();
      expect(find.text('Giao dịch'), findsNWidgets(2));

      // Rời sang Báo cáo rồi quay lại Giao dịch.
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      // Header Giao dịch vẫn hiển thị, đúng vùng đã chọn.
      expect(find.text('Giao dịch'), findsNWidgets(2));
      expect(find.text('Báo cáo'), findsOneWidget);
    });
  });
}
