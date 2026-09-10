import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';

/// Bắt mọi literal ngay trước `.tr`/`.trArgs`/`.trParams`.
final _trLiteral = RegExp(
  r"'((?:[^'\\\n]|\\.)*)'\s*\.(?:tr|trArgs|trParams)\b",
);

/// Literal dùng làm khoá dịch trong `lib/` (bỏ phần comment cuối dòng để khỏi
/// bắt chuỗi nằm trong ghi chú).
Set<String> _keysUsedInLib() {
  final keys = <String>{};
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    _usedIn(entity.readAsStringSync(), keys);
  }
  return keys;
}

void _usedIn(String source, Set<String> keys) {
  for (var line in source.split('\n')) {
    final comment = line.indexOf('//');
    if (comment >= 0) line = line.substring(0, comment);
    for (final m in _trLiteral.allMatches(line)) {
      final key = m.group(1)!;
      if (key.isNotEmpty) keys.add(key);
    }
  }
}

void main() {
  final en = SoraTranslations().keys['en']!;

  test('chỉ nhánh en, bản đồ không rỗng (R4)', () {
    final keys = SoraTranslations().keys;
    expect(keys.containsKey('vi'), isFalse,
        reason: 'Không cần bản đồ tiếng Việt — khoá đã là chuỗi tiếng Việt');
    expect(en, isNotEmpty);
  });

  test('mọi literal gắn .tr trong lib/ đều có bản dịch en (R11)', () {
    final missing = _keysUsedInLib().where((k) => !en.containsKey(k)).toList()
      ..sort();
    expect(
      missing,
      isEmpty,
      reason: 'Thiếu bản dịch en cho: ${missing.join(' | ')}',
    );
  });

  test('15 tên danh mục mặc định của CategorySource đều có bản dịch (R11)', () {
    // Tên gọi qua biến (`category.name.tr`) nên regex ở test trên không bắt được.
    final missing = CategorySource.all
        .map((c) => c.name)
        .where((name) => !en.containsKey(name))
        .toList();
    expect(
      missing,
      isEmpty,
      reason: 'Thiếu bản dịch en cho tên danh mục: ${missing.join(' | ')}',
    );
  });

  test('không có bản dịch rỗng', () {
    en.forEach((key, value) {
      expect(value.trim(), isNotEmpty, reason: 'Bản dịch rỗng cho "$key"');
    });
  });
}
