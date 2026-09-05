import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';

import 'fakes/fake_wallet_repository.dart';

Wallet _draft({int id = 0, String name = 'Mới', WalletType type = WalletType.cash,
    int balance = 1000}) => Wallet(
  id: id,
  name: name,
  type: type,
  icon: '💵',
  initialBalance: balance,
  balance: balance,
  isHidden: false,
);

int _countDefault(List<Wallet> wallets) =>
    wallets.where((w) => w.isDefault && !w.isHidden).length;

void main() {
  group('WalletController — cache reactive + bất biến mặc định', () {
    test('init nạp 5 ví mẫu + loading tắt, đúng 1 mặc định', () async {
      final repo = FakeWalletRepository();
      final controller = WalletController(repo);
      expect(controller.isLoading, isTrue);

      await controller.init();

      expect(controller.isLoading, isFalse);
      expect(controller.wallets.length, 5);
      expect(_countDefault(controller.wallets), 1);
      expect(
        controller.wallets.firstWhere((w) => w.isDefault).name,
        'Tiền mặt',
      );
    });

    test('tạo ví đầu tiên trên list rỗng → ép default (acceptance 3)', () async {
      final controller = WalletController(FakeWalletRepository([]));
      await controller.init();

      final created = await controller.create(_draft(), wantDefault: false);

      expect(created.isDefault, isTrue);
      expect(_countDefault(controller.wallets), 1);
      expect(controller.wallets.single.name, 'Mới');
    });

    test('bật mặc định cho ví mới → dời cờ khỏi ví default cũ (acceptance 4)', () async {
      final controller = WalletController(FakeWalletRepository());
      await controller.init();

      final created = await controller.create(
        _draft(name: 'Thêm B', type: WalletType.bank, balance: 5000),
        wantDefault: true,
      );

      expect(created.isDefault, isTrue);
      expect(_countDefault(controller.wallets), 1);
      expect(
        controller.wallets.firstWhere((w) => w.id == 1).isDefault,
        isFalse, // Tiền mặt hết mặc định
      );
      expect(controller.wallets.firstWhere((w) => w.isDefault).id,
          created.id);
    });

    test('tạo ví không bật mặc định khi đã có default → không tạo default thứ 2', () async {
      final controller = WalletController(FakeWalletRepository());
      await controller.init();

      await controller.create(_draft(name: 'Phụ', balance: 2000));

      expect(_countDefault(controller.wallets), 1);
    });

    test('update đổi tên/icon — cache phản ánh ngay, giữ default, giữ is_hidden', () async {
      final repo = FakeWalletRepository();
      final controller = WalletController(repo);
      await controller.init();

      final cash = controller.wallets.firstWhere((w) => w.id == 1);
      final saved = await controller.updateWallet(
        cash.copyWith(name: 'Tiền mặt 2', icon: '💰'),
      );

      expect(saved.name, 'Tiền mặt 2');
      expect(saved.icon, '💰');
      expect(saved.isDefault, isTrue); // không bật/tắt → giữ
      expect(_countDefault(controller.wallets), 1);
      expect(repo.allStored.firstWhere((w) => w.id == 1).isHidden, isFalse);
      expect(
        controller.wallets.firstWhere((w) => w.id == 1).name,
        'Tiền mặt 2',
      );
    });

    test('sửa ví chưa giao dịch đổi số dư → ghi cả initial_balance và balance (acceptance 7)', () async {
      final repo = FakeWalletRepository();
      final controller = WalletController(repo);
      await controller.init();

      // Tạo ví mới (chưa có giao dịch) — không phải default.
      final fresh = await controller.create(
        _draft(name: 'Ví mới', balance: 1000000),
      );
      final updated = await controller.updateWallet(
        fresh.copyWith(initialBalance: 2000000, balance: 2000000),
      );

      expect(updated.balance, 2000000);
      expect(updated.initialBalanceValue, 2000000);
      final stored = repo.allStored.firstWhere((w) => w.id == fresh.id);
      expect(stored.initialBalanceValue, 2000000);
      expect(stored.balance, 2000000);
    });

    test('tắt cờ default khi còn active khác → tự chọn active đầu làm thay thế (FR-008)', () async {
      final controller = WalletController(FakeWalletRepository());
      await controller.init();

      final cash = controller.wallets.firstWhere((w) => w.id == 1); // default
      await controller.updateWallet(cash, wantDefault: false);

      expect(_countDefault(controller.wallets), 1);
      expect(controller.wallets.firstWhere((w) => w.id == 1).isDefault, isFalse);
      // Replacement = ví active đầu theo sortOrder, trừ chính cash → Vietcombank.
      expect(controller.wallets.firstWhere((w) => w.isDefault).id, 2);
    });

    test('chặn tắt cờ khi chỉ còn mình nó hoạt động (FR-008)', () async {
      final repo = FakeWalletRepository([]);
      final controller = WalletController(repo);
      await controller.init();

      // Ví đầu tiên (duy nhất active) được ép default.
      final created = await controller.create(_draft());
      expect(created.isDefault, isTrue);
      expect(controller.wallets.single.isDefault, isTrue);

      final only = controller.wallets.single;
      final updated = await controller.updateWallet(only, wantDefault: false);

      expect(updated.isDefault, isTrue); // không cho tắt
      expect(_countDefault(controller.wallets), 1);
    });
  });

  group('WalletController — chuyển tiền & đọc giao dịch (PBI 8)', () {
    test('transfer gọi repo → reload cache 2 ví đúng số dư (acceptance 7, SC-002)', () async {
      final controller = WalletController(FakeWalletRepository());
      await controller.init();

      await controller.transfer(
        fromId: 2,
        toId: 4,
        amount: 2000000,
        date: DateTime(2026, 9, 5, 9, 30),
        note: 'Nạp tiền ví điện tử',
      );

      final vcb = controller.wallets.firstWhere((w) => w.id == 2);
      expect(vcb.balance, 12800000); // 14.800.000 − 2.000.000
      final momo = controller.wallets.firstWhere((w) => w.id == 4);
      expect(momo.balance, 3450000); // 1.450.000 + 2.000.000
    });

    test('transactionsOf trả đúng giao dịch của ví, có vế chuyển mới (FR-008/014)', () async {
      final controller = WalletController(FakeWalletRepository());
      await controller.init();

      // Seed mặc định: Vietcombank (id 2) có 6 dòng; Sổ tiết kiệm (id 5) rỗng.
      expect((await controller.transactionsOf(2)).length, 6);
      expect(await controller.transactionsOf(5), isEmpty);

      await controller.transfer(
        fromId: 2,
        toId: 4,
        amount: 2000000,
        date: DateTime(2026, 9, 5, 9, 30),
        note: 'Nạp tiền ví điện tử',
      );

      final vcbTx = await controller.transactionsOf(2);
      expect(vcbTx.length, 7);
      expect(
        vcbTx.where(
          (t) => t.type == TxnType.transfer && t.amount == -2000000,
        ),
        hasLength(1),
      );

      final momoTx = await controller.transactionsOf(4);
      expect(momoTx.length, 2);
      expect(
        momoTx.where(
          (t) => t.type == TxnType.transfer && t.amount == 2000000,
        ),
        hasLength(1),
      );
    });
  });
}
