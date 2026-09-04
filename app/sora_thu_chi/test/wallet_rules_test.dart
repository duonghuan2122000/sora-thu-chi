import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_rules.dart';

Wallet _wallet(
  int id,
  String name, {
  bool isDefault = false,
  bool isHidden = false,
  int sortOrder = 0,
}) => Wallet(
  id: id,
  name: name,
  type: WalletType.cash,
  icon: '💵',
  balance: 1000,
  isDefault: isDefault,
  isHidden: isHidden,
  sortOrder: sortOrder,
);

int _countDefault(List<Wallet> wallets) =>
    wallets.where((w) => w.isDefault && !w.isHidden).length;

void main() {
  group('wallet_rules — bất biến ví mặc định', () {
    test('list rỗng → tạo ví đầu tiên ép isDefault=true, đúng 1 default (acceptance 3)', () {
      final decision = resolveOnCreate(const [], _wallet(1, 'Tiền mặt'),
          wantDefault: false);
      expect(decision.draft.isDefault, isTrue);
      expect(decision.demote, isNull);
      expect(_countDefault([decision.draft]), 1);
    });

    test('đã có ví hoạt động, không bật mặc định → ví mới không default', () {
      final list = [_wallet(1, 'A', isDefault: true, sortOrder: 1)];
      final decision = resolveOnCreate(list, _wallet(2, 'B'),
          wantDefault: false);
      expect(decision.draft.isDefault, isFalse);
      expect(decision.demote, isNull);
    });

    test('bật default cho ví B khi đang có A default → B default, A bị dời cờ (acceptance 4)', () {
      final a = _wallet(1, 'A', isDefault: true, sortOrder: 1);
      final b = _wallet(2, 'B', sortOrder: 2);
      final decision = resolveOnCreate([a, b], b, wantDefault: true);
      expect(decision.draft.isDefault, isTrue);
      expect(decision.demote?.id, a.id);
    });

    test('sửa B (không default) bật mặc định → edited default, demote A', () {
      final a = _wallet(1, 'A', isDefault: true, sortOrder: 1);
      final b = _wallet(2, 'B', sortOrder: 2);
      final d = resolveOnUpdate([a, b], b,
          wasDefault: false, wantDefault: true);
      expect(d.edited.isDefault, isTrue);
      expect(d.demote?.id, a.id);
      expect(d.promote, isNull);
    });

    test('tắt cờ default A khi còn active khác → A hết cờ, chọn active đầu thay thế', () {
      final a = _wallet(1, 'A', isDefault: true, sortOrder: 1);
      final b = _wallet(2, 'B', sortOrder: 2);
      final c = _wallet(3, 'C', sortOrder: 3);
      final d = resolveOnUpdate([a, b, c], a,
          wasDefault: true, wantDefault: false);
      expect(d.edited.isDefault, isFalse);
      expect(d.promote?.id, b.id); // active đầu theo sortOrder, trừ chính A
      expect(d.demote, isNull);
    });

    test('chặn tắt khi A là default duy nhất active (FR-008, SC-005)', () {
      final a = _wallet(1, 'A', isDefault: true, sortOrder: 1);
      final d = resolveOnUpdate([a], a, wasDefault: true, wantDefault: false);
      expect(d.edited.isDefault, isTrue); // giữ default
      expect(d.promote, isNull);
      expect(d.demote, isNull);
    });

    test('ví ẩn không tính là active: chỉ còn ví ẩn → ví mới ép default', () {
      final hidden = _wallet(1, 'H', isDefault: true, isHidden: true);
      expect(activeWalletCount([hidden]), 0);
      expect(hasActiveDefault([hidden]), isFalse);
      final decision = resolveOnCreate([hidden], _wallet(2, 'Mới'),
          wantDefault: false);
      expect(decision.draft.isDefault, isTrue);
    });

    test('hasActiveDefault bỏ qua ví ẩn mang cờ', () {
      final list = [
        _wallet(1, 'A', sortOrder: 1),
        _wallet(2, 'H', isDefault: true, isHidden: true, sortOrder: 2),
      ];
      expect(hasActiveDefault(list), isFalse);
    });

    test('firstActiveByDisplayOrder chọn ví active đầu theo sortOrder, trừ excludeId', () {
      final list = [
        _wallet(1, 'A', isHidden: true, sortOrder: 1),
        _wallet(2, 'B', sortOrder: 5),
        _wallet(3, 'C', sortOrder: 2),
      ];
      final w = firstActiveByDisplayOrder(list);
      expect(w?.id, 3); // C sortOrder 2, ẩn bị bỏ
      final w2 = firstActiveByDisplayOrder(list, excludeId: 3);
      expect(w2?.id, 2);
    });
  });
}
