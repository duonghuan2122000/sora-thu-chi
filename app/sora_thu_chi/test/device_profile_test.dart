import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/profile/device_profile.dart';

void main() {
  group('DeviceProfile', () {
    test('initial → tên mặc định + tiền tệ VND', () {
      const p = DeviceProfile.initial;
      expect(p.resolvedDisplayName, 'Người dùng');
      expect(p.currencyCode, 'VND');
    });

    test('đã đặt tên → resolved trả tên người dùng', () {
      const p = DeviceProfile(displayName: 'Lan');
      expect(p.resolvedDisplayName, 'Lan');
    });
  });

  group('initialsOf', () {
    test('tên mặc định 2 từ → ND', () {
      expect(initialsOf('Người dùng'), 'ND');
    });

    test('tên 1 từ → chữ cái đầu', () {
      expect(initialsOf('Lan'), 'L');
    });

    test('2 từ → chữ cái đầu mỗi từ', () {
      expect(initialsOf('Huân Anh'), 'HA');
    });

    test('rỗng → chuỗi rỗng', () {
      expect(initialsOf(''), '');
    });
  });
}
