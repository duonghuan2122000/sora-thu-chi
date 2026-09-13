import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Bất biến asset nhận diện — `.specify/specs/25/contracts/brand-assets.md` §6.
// Đọc thẳng file trong repo (không cần emulator/thiết bị); đường dẫn tính từ gốc
// package vì `flutter test` chạy với cwd = gốc package.

const _res = 'android/app/src/main/res';
const _appIconDir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _launchImageDir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
const _storyboard = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';

const _tealRgb = [0x0F, 0x6E, 0x56];
const _coralRgb = [0xD8, 0x5A, 0x30];
const _whiteRgb = [0xFF, 0xFF, 0xFF];

/// Màu teal viết bằng số thực trong `LaunchScreen.storyboard`.
const _tealStoryboard =
    'red="0.058823529411764705" green="0.43137254901960786" blue="0.33725490196078434"';

bool _sameRgb(img.Pixel p, List<int> rgb) =>
    p.r.toInt() == rgb[0] && p.g.toInt() == rgb[1] && p.b.toInt() == rgb[2];

void main() {
  group('Asset Android — icon launcher (adaptive icon)', () {
    test('đủ 3 file của adaptive icon', () {
      for (final path in [
        '$_res/drawable/ic_launcher_foreground.xml',
        '$_res/values/ic_launcher_background.xml',
        '$_res/mipmap-anydpi-v26/ic_launcher.xml',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: 'thiếu $path');
      }
    });

    test('không còn icon mặc định của flutter create', () {
      final leftovers = Directory(_res)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('mipmap-') && f.path.endsWith('ic_launcher.png'))
          .map((f) => f.path)
          .toList();
      expect(leftovers, isEmpty);
    });

    test('ic_launcher.xml là adaptive-icon', () {
      final xml = File('$_res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
      expect(xml, contains('adaptive-icon'));
      expect(xml, contains('@drawable/ic_launcher_foreground'));
      expect(xml, contains('@color/ic_launcher_background'));
    });

    test('mọi path đường tròn dùng dạng cung tuyệt đối (Android bỏ qua dạng '
        'viết tắt `a ... 0 1 0 ...` ⇒ vector ra rỗng, mất nửa teal + vòng trắng)',
        () {
      for (final path in [
        '$_res/drawable/ic_launcher_foreground.xml',
        '$_res/drawable/splash_logo.xml',
        '$_res/drawable/splash_logo_masked.xml',
      ]) {
        final xml = File(path).readAsStringSync();
        expect(xml, isNot(contains(' a ')), reason: path);
        expect(xml, isNot(contains(' 0 1 0 ')), reason: path);
        expect(xml, contains('A '), reason: path);
      }
    });

    test('foreground chứa đủ 3 mã màu thương hiệu', () {
      final xml = File('$_res/drawable/ic_launcher_foreground.xml').readAsStringSync();
      expect(xml, contains('#FF0F6E56')); // teal
      expect(xml, contains('#FFD85A30')); // coral
      expect(xml, contains('#FFFFFFFF')); // trắng
    });
  });

  group('Asset iOS — icon launcher', () {
    test('đủ 15 tên file khai trong Contents.json', () {
      final manifest =
          jsonDecode(File('$_appIconDir/Contents.json').readAsStringSync())
              as Map<String, dynamic>;
      final names = (manifest['images'] as List)
          .cast<Map<String, dynamic>>()
          .map((e) => e['filename'] as String)
          .toSet();
      expect(names, hasLength(15));
      for (final name in names) {
        expect(File('$_appIconDir/$name').existsSync(), isTrue,
            reason: 'thiếu $name');
      }
    });

    test('icon 1024 đục hoàn toàn (iOS không nhận PNG trong suốt)', () {
      final png = img.decodePng(
          File('$_appIconDir/Icon-App-1024x1024@1x.png').readAsBytesSync())!;
      expect(png.width, 1024);
      for (final p in png) {
        if (p.a.toInt() != 255) {
          fail('pixel (${p.x},${p.y}) alpha=${p.a.toInt()} — phải đục');
        }
      }
    });
  });

  group('Asset Flutter — logo splash', () {
    test('tồn tại, nền trong suốt ở 4 góc và có đủ 3 màu thương hiệu', () {
      final png = img.decodePng(
          File('assets/brand/coin_flow_logo.png').readAsBytesSync())!;
      expect(png.width, 1024);

      for (final p in [
        (0, 0),
        (png.width - 1, 0),
        (0, png.height - 1),
        (png.width - 1, png.height - 1),
      ]) {
        expect(png.getPixel(p.$1, p.$2).a.toInt(), 0,
            reason: 'góc ${p.$1},${p.$2} phải trong suốt (không khung nền)');
      }

      final found = <String>{};
      for (final p in png) {
        if (p.a.toInt() != 255) continue;
        if (_sameRgb(p, _tealRgb)) found.add('teal');
        if (_sameRgb(p, _coralRgb)) found.add('coral');
        if (_sameRgb(p, _whiteRgb)) found.add('white');
      }
      expect(found, {'teal', 'coral', 'white'});
    });
  });

  group('Splash tầng native — nền teal, không còn khung trắng (FR-010)', () {
    test('colors.xml khai báo teal thương hiệu', () {
      expect(File('$_res/values/colors.xml').readAsStringSync(),
          contains('#FF0F6E56'));
    });

    test('launch_background.xml (cả 2 biến thể) dùng teal, bỏ white/colorBackground',
        () {
      for (final path in [
        '$_res/drawable/launch_background.xml',
        '$_res/drawable-v21/launch_background.xml',
      ]) {
        final xml = File(path).readAsStringSync();
        expect(xml, contains('@color/brand_teal'), reason: path);
        expect(xml, contains('@drawable/splash_logo'), reason: path);
        expect(xml, isNot(contains('@android:color/white')), reason: path);
        expect(xml, isNot(contains('?android:colorBackground')), reason: path);
      }
    });

    test('values-v31/styles.xml dùng SplashScreen API với nền teal', () {
      final xml = File('$_res/values-v31/styles.xml').readAsStringSync();
      expect(xml, contains('windowSplashScreenBackground'));
      expect(xml, contains('windowSplashScreenAnimatedIcon'));
      expect(xml, contains('@color/brand_teal'));
      expect(xml, isNot(contains('?android:colorBackground')));
      // Icon splash của Android 12+ bị hệ thống cắt theo đường tròn ~2/3 khung
      // ⇒ phải dùng biến thể thu nhỏ, không dùng bản 0.88 của `launch_background`.
      expect(xml, contains('@drawable/splash_logo_masked'));
    });

    test('storyboard iOS nền teal, không còn nền trắng', () {
      final xml = File(_storyboard).readAsStringSync();
      expect(xml, contains(_tealStoryboard));
      expect(xml, contains('LaunchImage'));
      expect(xml, contains('Sora Thu Chi'));
      // Nền view: teal — không còn giá trị trắng của bản mặc định.
      expect(xml, contains('<color key="backgroundColor" $_tealStoryboard'));
      expect(
          xml, isNot(contains('<color key="backgroundColor" red="1" green="1"')));
    });

    test('LaunchImage 1x/2x/3x đúng cỡ, nền trong suốt ở góc', () {
      for (final e in {'': 120, '@2x': 240, '@3x': 360}.entries) {
        final png = img.decodePng(
            File('$_launchImageDir/LaunchImage${e.key}.png').readAsBytesSync())!;
        expect(png.width, e.value);
        expect(png.getPixel(0, 0).a.toInt(), 0);
        expect(png.getPixel(png.width - 1, png.height - 1).a.toInt(), 0);
      }
    });
  });

  group('Bản sạch — không lọt chú thích của file thiết kế (FR-011)', () {
    test('không asset XML nào chứa chuỗi chú thích concept', () {
      const banned = ['Concept A', 'Coin Flow', 'Thu (teal)'];
      final files = Directory(_res)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.xml'));
      for (final f in files) {
        final text = f.readAsStringSync();
        for (final s in banned) {
          expect(text, isNot(contains(s)), reason: '${f.path} chứa "$s"');
        }
      }
    });
  });
}
