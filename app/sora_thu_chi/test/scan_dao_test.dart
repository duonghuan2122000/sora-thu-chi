import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/data/db/app_database.dart';
import 'package:sora_thu_chi/data/wallet_repository_drift.dart';

/// Mở DB drift trong bộ nhớ. Host thiếu sqlite native → trả null (skip-guard,
/// như `transactions_dao_test`).
Future<AppDatabase?> _tryMemoryDb() async {
  try {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    return db;
  } catch (_) {
    return null;
  }
}

/// Thư mục tạm cho test migration (cần file thật để mở lại connection).
Future<Directory?> _tryTempDir() async {
  try {
    return await Directory.systemTemp.createTemp('sora_scan_migration');
  } catch (_) {
    return null;
  }
}

const _skip = 'Host thiếu sqlite native — bỏ qua DAO drift tích hợp.';

void main() {
  group('addScannedTransaction (FR-033/FR-034, R11)', () {
    test('1 giao dịch nguồn aiScan + 1 phiên quét trỏ đúng giao dịch', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped(_skip);
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final before = await repo.loadAll();
      final wallet = before.firstWhere((w) => !w.isHidden);

      await repo.addScannedTransaction(
        walletId: wallet.id,
        type: TxnType.expense,
        amount: 55000,
        date: DateTime(2026, 9, 12, 8, 24),
        category: const Category(
          id: 1,
          name: 'Ăn uống',
          type: CategoryType.expense,
          icon: 'restaurant',
          color: 0xFF3D8C77,
        ),
        note: 'CIRCLE K VIỆT NAM',
        receiptImage: '/tmp/receipts/1.jpg',
        engine: ScanEngine.ruleBased,
        rawText: 'CIRCLE K\nTỔNG CỘNG 55.000',
        parsedJson: '{"amount":55000}',
        createdAt: DateTime(2026, 9, 12, 8, 25),
      );

      final txns = await db.select(db.transactions).get();
      final created = txns.last;
      expect(created.type, TxnType.expense);
      expect(created.amount, -55000);
      expect(created.source, TxnSource.aiScan);
      expect(created.note, 'CIRCLE K VIỆT NAM');
      expect(created.receiptImage, '/tmp/receipts/1.jpg');
      expect(created.categoryId, 1);

      final sessions = await db.select(db.scanSessions).get();
      expect(sessions, hasLength(1));
      expect(sessions.single.transactionId, created.id);
      expect(sessions.single.engine, ScanEngine.ruleBased);
      expect(sessions.single.rawText, contains('TỔNG CỘNG'));
      expect(sessions.single.createdAt, DateTime(2026, 9, 12, 8, 25));

      // Số dư ví bù đúng dấu theo loại chi.
      final after = await repo.loadAll();
      final updated = after.firstWhere((w) => w.id == wallet.id);
      expect(updated.balance, wallet.balance - 55000);
    });

    test('khoản thu → cộng số dư; danh mục null vẫn ghi được', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped(_skip);
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final wallet = (await repo.loadAll()).firstWhere((w) => !w.isHidden);

      await repo.addScannedTransaction(
        walletId: wallet.id,
        type: TxnType.income,
        amount: 200000,
        date: DateTime(2026, 9, 12),
        receiptImage: '/tmp/receipts/2.jpg',
        engine: ScanEngine.ruleBased,
        rawText: 'THU NHAP',
        parsedJson: '{}',
      );

      final created = (await db.select(db.transactions).get()).last;
      expect(created.amount, 200000);
      expect(created.categoryId, isNull);
      expect(created.category, '');
      expect((await repo.loadAll()).firstWhere((w) => w.id == wallet.id).balance,
          wallet.balance + 200000);
    });

    test('allTransactions trả giao dịch quét với source = aiScan', () async {
      final db = await _tryMemoryDb();
      if (db == null) {
        markTestSkipped(_skip);
        return;
      }
      addTearDown(db.close);
      final repo = DriftWalletRepository(db);
      final wallet = (await repo.loadAll()).firstWhere((w) => !w.isHidden);

      await repo.addScannedTransaction(
        walletId: wallet.id,
        type: TxnType.expense,
        amount: 30000,
        date: DateTime(2026, 9, 12),
        receiptImage: '/tmp/receipts/3.jpg',
        engine: ScanEngine.ruleBased,
        rawText: 'x',
        parsedJson: '{}',
      );

      final all = await repo.allTransactions();
      final scanned = all.where((t) => t.amount == -30000).toList();
      expect(scanned, hasLength(1));
      expect(scanned.single.source, TxnSource.aiScan);
      // Dòng cũ/seed vẫn là manual.
      expect(all.where((t) => t.source == TxnSource.manual), isNotEmpty);
    });
  });

  group('migration v7 → v8 (data-model §1.3)', () {
    test('dòng cũ nhận source = manual, bảng scan_sessions rỗng', () async {
      final dir = await _tryTempDir();
      if (dir == null) {
        markTestSkipped(_skip);
        return;
      }
      addTearDown(() => dir.delete(recursive: true));
      final file = File(p.join(dir.path, 'sora.sqlite'));

      // (1) Tạo DB v8 rồi "hạ cấp" về đúng hình dạng v7: bỏ cột source + bảng
      //     scan_sessions, đặt user_version = 7.
      final created = AppDatabase(NativeDatabase(file));
      await created.customSelect('SELECT 1').get();
      expect(created.schemaVersion, 9);
      try {
        await created.customStatement('ALTER TABLE transactions DROP COLUMN source');
      } catch (_) {
        await created.close();
        markTestSkipped('sqlite bản này không hỗ trợ DROP COLUMN — bỏ qua.');
        return;
      }
      await created.customStatement('DROP TABLE scan_sessions');
      await created.customStatement('PRAGMA user_version = 7');
      await created.close();

      // (2) Mở lại → drift chạy onUpgrade(from: 7) → thêm cột + tạo bảng.
      final upgraded = AppDatabase(NativeDatabase(file));
      addTearDown(upgraded.close);
      final rows = await upgraded.select(upgraded.transactions).get();
      expect(rows, isNotEmpty, reason: 'seed cũ phải còn nguyên');
      expect(rows.every((r) => r.source == TxnSource.manual), isTrue,
          reason: 'dòng cũ nhận default manual');
      expect(await upgraded.select(upgraded.scanSessions).get(), isEmpty,
          reason: 'bảng phiên quét KHÔNG seed');
    });
  });
}
