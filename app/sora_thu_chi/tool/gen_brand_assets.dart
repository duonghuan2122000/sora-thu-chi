/// Sinh toàn bộ asset nhận diện Sora Thu Chi (icon launcher + logo splash) từ
/// **một nguồn hình học duy nhất** — Concept A "Coin Flow".
///
/// Chạy: `dart run tool/gen_brand_assets.dart` (đứng ở `app/sora_thu_chi/`).
///
/// Hình học trích từ `docs/logo/logo-concept-a-coin-flow.svg`: viewBox 400×420,
/// coin `r=70` ⇒ đường kính `D=140`; mọi kích thước dưới đây là bội số của `D`.
/// Tỉ lệ chốt ở `.specify/specs/25/contracts/brand-assets.md` §2. Phần raster
/// (PNG) và phần vector (VectorDrawable) cùng đọc bộ số này ⇒ hai nền tảng
/// không lệch hình.
library;

import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

// ---------------------------------------------------------------------------
// Bảng màu thương hiệu (design system — không gradient/đổ bóng, FR-008).
// ---------------------------------------------------------------------------

const int brandTeal = 0xFF0F6E56;
const int brandCoral = 0xFFD85A30;
const int brandWhite = 0xFFFFFFFF;

// ---------------------------------------------------------------------------
// Tỉ lệ hình học (contracts/brand-assets.md §2).
// ---------------------------------------------------------------------------

/// Coin / cạnh icon launcher — nằm trong vùng an toàn của adaptive icon.
const double coinRatioIcon = 0.68;

/// Coin / cạnh khung logo splash (lề 6% mỗi cạnh).
const double coinRatioSplash = 0.88;

/// Coin / cạnh khung **icon splash của Android 12+**.
///
/// Hệ thống scale drawable lên ~277dp rồi **cắt theo đường tròn ~192dp** ⇒ nội
/// dung phải nằm gọn trong đường tròn đó, nếu không vòng viền trắng bị cắt mất
/// (đã quan sát trên emulator với 0.88: nửa teal chìm vào nền, mất vòng).
/// 0.44 cho coin hiện ra ~123dp — **khớp** cỡ logo tầng Flutter (0.88 × 140dp).
const double coinRatioSplashNative = 0.44;

/// Dày đường phân tách hai nửa (× D).
const double sepRatio = 0.021;

/// Dày nét mũi tên Thu/Chi (× D).
const double arrowRatio = 0.05;

/// Dày vòng viền trắng quanh coin (× D) — phần thêm của PBI 25 (FR-016).
const double ringRatio = 0.03;

// Hình học lấy nguyên từ SVG concept, quy về bội số của D.
const double _svgDiameter = 140;
const double _arrowHalfSpan = 15 / _svgDiameter;
const double _arrowBase = 20 / _svgDiameter;
const double _arrowApex = 38 / _svgDiameter;

/// Hình học Concept A đặt trong khung vuông cạnh [size], coin chiếm [coinRatio].
///
/// Toạ độ tuyệt đối trong khung; dùng chung cho cả phần raster lẫn phần vector.
class CoinGeometry {
  CoinGeometry(this.size, this.coinRatio)
      : cx = size / 2,
        cy = size / 2,
        d = size * coinRatio;

  final double size;
  final double coinRatio;
  final double cx;
  final double cy;
  final double d;

  double get r => d / 2;
  double get sepWidth => sepRatio * d;
  double get arrowWidth => arrowRatio * d;
  double get ringWidth => ringRatio * d;

  double get sepY => cy;
  double get sepLeft => cx - r;
  double get sepRight => cx + r;

  double get arrowLeftX => cx - _arrowHalfSpan * d;
  double get arrowRightX => cx + _arrowHalfSpan * d;
  double get upBaseY => cy - _arrowBase * d;
  double get upApexY => cy - _arrowApex * d;
  double get downBaseY => cy + _arrowBase * d;
  double get downApexY => cy + _arrowApex * d;

  /// Đường tròn đầy (nửa teal phủ cả coin rồi nửa coral đè lên nửa dưới).
  ///
  /// Vẽ bằng **2 cung bán nguyệt tuyệt đối** (`A`, `large-arc=0`) — đúng dạng
  /// cung đã kiểm chứng vẽ được trên Android. Dạng viết tắt
  /// `a r,r 0 1 0 2r,0 a r,r 0 1 0 -2r,0 Z` bị `VectorDrawable` bỏ qua (path
  /// rỗng) ⇒ mất cả nửa teal lẫn vòng viền trắng.
  String get circlePath =>
      'M ${_n(cx - r)},${_n(cy)} '
      'A ${_n(r)},${_n(r)} 0 0 1 ${_n(cx + r)},${_n(cy)} '
      'A ${_n(r)},${_n(r)} 0 0 1 ${_n(cx - r)},${_n(cy)} Z';

  /// Nửa dưới coin. `sweep=0` ⇒ cung chạy theo chiều giảm góc, qua **đáy**
  /// (hệ toạ độ SVG có trục y hướng xuống).
  String get bottomHalfPath =>
      'M ${_n(sepLeft)},${_n(sepY)} '
      'A ${_n(r)},${_n(r)} 0 0 0 ${_n(sepRight)},${_n(sepY)} Z';

  String get separatorPath =>
      'M ${_n(sepLeft)},${_n(sepY)} L ${_n(sepRight)},${_n(sepY)}';

  String get upArrowPath =>
      'M ${_n(arrowLeftX)},${_n(upBaseY)} '
      'L ${_n(cx)},${_n(upApexY)} '
      'L ${_n(arrowRightX)},${_n(upBaseY)}';

  String get downArrowPath =>
      'M ${_n(arrowLeftX)},${_n(downBaseY)} '
      'L ${_n(cx)},${_n(downApexY)} '
      'L ${_n(arrowRightX)},${_n(downBaseY)}';
}

/// Số thực gọn cho `pathData`: 3 chữ số thập phân, bỏ đuôi `.000`.
String _n(double v) {
  final s = v.toStringAsFixed(3);
  return s.endsWith('.000') ? s.substring(0, s.length - 4) : s;
}

// ---------------------------------------------------------------------------
// Phần raster (PNG) — package `image`, không thêm dependency.
// ---------------------------------------------------------------------------

/// Hệ số siêu mẫu: vẽ ở 4× rồi thu nhỏ bằng trung bình ⇒ khử răng cưa mà không
/// cần tới `antialias` của từng hàm vẽ.
const int _supersample = 4;

img.Color _rgb(int argb) => img.ColorRgba8(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    );

/// Vẽ logo Concept A lên ảnh [size]×[size] với coin chiếm [coinRatio].
///
/// [background] `null` ⇒ nền trong suốt (logo splash đặt trên nền teal của
/// Flutter/native); truyền [brandTeal] ⇒ nền teal **đục** (yêu cầu của iOS).
img.Image renderCoin(int size, {required double coinRatio, int? background}) {
  final s = size * _supersample;
  var canvas = img.Image(width: s, height: s, numChannels: 4);
  if (background != null) {
    img.fill(canvas, color: _rgb(background));
  }
  _paintCoin(canvas, CoinGeometry(s.toDouble(), coinRatio));
  canvas = img.copyResize(
    canvas,
    width: size,
    height: size,
    interpolation: img.Interpolation.average,
  );
  return canvas;
}

void _paintCoin(img.Image c, CoinGeometry g) {
  final teal = _rgb(brandTeal);
  final coral = _rgb(brandCoral);
  final white = _rgb(brandWhite);

  // Coin: quét từng pixel trong hộp bao — nửa trên teal, nửa dưới coral. Cách
  // này thay cho `clipPath` của SVG và không cần mặt nạ trung gian.
  final r = g.r;
  for (var y = (g.cy - r).floor(); y <= (g.cy + r).ceil(); y++) {
    for (var x = (g.cx - r).floor(); x <= (g.cx + r).ceil(); x++) {
      final dx = x + 0.5 - g.cx;
      final dy = y + 0.5 - g.cy;
      if (dx * dx + dy * dy > r * r) continue;
      final col = y + 0.5 < g.cy ? teal : coral;
      c.setPixelRgba(
        x,
        y,
        col.r.toInt(),
        col.g.toInt(),
        col.b.toInt(),
        col.a.toInt(),
      );
    }
  }

  // Đường phân tách hai nửa (đầu nét bằng, đúng như SVG concept).
  _thickLine(c, g.sepLeft, g.sepY, g.sepRight, g.sepY, g.sepWidth, white,
      roundCaps: false);
  // Hai mũi tên: Thu (lên, nửa teal) và Chi (xuống, nửa coral).
  _thickLine(c, g.arrowLeftX, g.upBaseY, g.cx, g.upApexY, g.arrowWidth, white,
      roundCaps: true);
  _thickLine(c, g.cx, g.upApexY, g.arrowRightX, g.upBaseY, g.arrowWidth, white,
      roundCaps: true);
  _thickLine(c, g.arrowLeftX, g.downBaseY, g.cx, g.downApexY, g.arrowWidth,
      white, roundCaps: true);
  _thickLine(c, g.cx, g.downApexY, g.arrowRightX, g.downBaseY, g.arrowWidth,
      white, roundCaps: true);

  // Vòng viền trắng quanh coin (FR-016): tô dày bằng các vòng tròn đồng tâm
  // vì `drawCircle` của package không có tham số bề dày.
  final outer = (r + g.ringWidth / 2).round();
  final inner = (r - g.ringWidth / 2).round();
  for (var rr = outer; rr >= inner; rr--) {
    img.drawCircle(c, x: g.cx.round(), y: g.cy.round(), radius: rr, color: white);
  }
}

/// Đoạn thẳng đậm; [roundCaps] thêm hai chấm tròn ở đầu mút (mô phỏng
/// `stroke-linecap="round"` của SVG).
void _thickLine(
  img.Image c,
  double x1,
  double y1,
  double x2,
  double y2,
  double width,
  img.Color color, {
  required bool roundCaps,
}) {
  final thickness = width.round() < 1 ? 1 : width.round();
  img.drawLine(
    c,
    x1: x1.round(),
    y1: y1.round(),
    x2: x2.round(),
    y2: y2.round(),
    color: color,
    thickness: thickness,
  );
  if (roundCaps) {
    final rad = (width / 2).round();
    img.fillCircle(c, x: x1.round(), y: y1.round(), radius: rad, color: color);
    img.fillCircle(c, x: x2.round(), y: y2.round(), radius: rad, color: color);
  }
}

// ---------------------------------------------------------------------------
// Phần vector — cùng bộ hình học, phát ra VectorDrawable XML cho Android.
// ---------------------------------------------------------------------------

/// Một phần tử hình học ở dạng vector.
class VectorPart {
  const VectorPart(
    this.pathData, {
    this.fill,
    this.stroke,
    this.strokeWidth,
    this.roundCaps = false,
  });

  final String pathData;
  final int? fill;
  final int? stroke;
  final double? strokeWidth;
  final bool roundCaps;
}

/// Các phần tử của logo theo đúng thứ tự vẽ: coin → đường phân tách → hai mũi
/// tên → vòng viền trắng.
List<VectorPart> coinVectorParts(CoinGeometry g) => [
      VectorPart(g.circlePath, fill: brandTeal),
      VectorPart(g.bottomHalfPath, fill: brandCoral),
      VectorPart(g.separatorPath, stroke: brandWhite, strokeWidth: g.sepWidth),
      VectorPart(g.upArrowPath,
          stroke: brandWhite, strokeWidth: g.arrowWidth, roundCaps: true),
      VectorPart(g.downArrowPath,
          stroke: brandWhite, strokeWidth: g.arrowWidth, roundCaps: true),
      VectorPart(g.circlePath, stroke: brandWhite, strokeWidth: g.ringWidth),
    ];

/// VectorDrawable [`viewport`×`viewport`] khai báo kích thước hiển thị [dp].
String vectorDrawable({
  required int viewport,
  required double dp,
  required List<VectorPart> parts,
}) {
  final b = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="utf-8"?>')
    ..writeln('<vector xmlns:android='
        '"http://schemas.android.com/apk/res/android"')
    ..writeln('    android:width="${_n(dp)}dp"')
    ..writeln('    android:height="${_n(dp)}dp"')
    ..writeln('    android:viewportWidth="$viewport"')
    ..writeln('    android:viewportHeight="$viewport">');
  for (final p in parts) {
    b.write('    <path android:pathData="${p.pathData}"');
    if (p.fill != null) {
      b.write(' android:fillColor="${_hex(p.fill!)}"');
    }
    if (p.stroke != null) {
      b.write(' android:strokeColor="${_hex(p.stroke!)}"');
      b.write(' android:strokeWidth="${_n(p.strokeWidth!)}"');
      if (p.roundCaps) {
        b.write(' android:strokeLineCap="round"'
            ' android:strokeLineJoin="round"');
      }
    }
    b.writeln('/>');
  }
  b.writeln('</vector>');
  return b.toString();
}

/// `0xAARRGGBB` → `#AARRGGBB` (định dạng màu của Android).
String _hex(int argb) =>
    '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';

// ---------------------------------------------------------------------------
// Ghi file
// ---------------------------------------------------------------------------

/// Gốc package `app/sora_thu_chi/` — suy từ vị trí script nên chạy được ở đâu cũng đúng.
final String appRoot = File.fromUri(Platform.script).parent.parent.path;

void _write(String path, String content) {
  final f = File(path)..createSync(recursive: true);
  f.writeAsStringSync(content);
  stdout.writeln('  $path');
}

void _writeBytes(String path, List<int> bytes) {
  final f = File(path)..createSync(recursive: true);
  f.writeAsBytesSync(bytes);
  stdout.writeln('  $path');
}

// ---------------------------------------------------------------------------
// Android — icon launcher (adaptive icon, minSdk 26 ⇒ chỉ cần anydpi-v26)
// ---------------------------------------------------------------------------

String get _androidRes => '$appRoot/android/app/src/main/res';

void genAndroidIcon() {
  final g = CoinGeometry(108, coinRatioIcon);
  _write(
    '$_androidRes/drawable/ic_launcher_foreground.xml',
    vectorDrawable(viewport: 108, dp: 108, parts: coinVectorParts(g)),
  );
  _write(
    '$_androidRes/values/ic_launcher_background.xml',
    '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="ic_launcher_background">${_hex(brandTeal)}</color>\n'
        '</resources>\n',
  );
  _write(
    '$_androidRes/mipmap-anydpi-v26/ic_launcher.xml',
    '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android='
        '"http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        '</adaptive-icon>\n',
  );
}

// ---------------------------------------------------------------------------
// iOS — ảnh splash tầng native: nền **trong suốt** vì storyboard đã đặt trên
// nền teal (đổi màu nền chỉ cần sửa storyboard, không phải sinh lại ảnh).
// ---------------------------------------------------------------------------

String get _iosLaunchImageDir =>
    '$appRoot/ios/Runner/Assets.xcassets/LaunchImage.imageset';

void genIosLaunchImage() {
  const scales = {'': 120, '@2x': 240, '@3x': 360};
  for (final e in scales.entries) {
    final png = renderCoin(e.value, coinRatio: coinRatioSplash);
    _writeBytes('$_iosLaunchImageDir/LaunchImage${e.key}.png', img.encodePng(png));
  }
}

// ---------------------------------------------------------------------------
// Flutter — logo màn splash: PNG nền **trong suốt** đặt trên nền teal của
// `PinGate` (FR-004/FR-016).
// ---------------------------------------------------------------------------

void genFlutterLogo() {
  final png = renderCoin(1024, coinRatio: coinRatioSplash);
  _writeBytes('$appRoot/assets/brand/coin_flow_logo.png', img.encodePng(png));
}

// ---------------------------------------------------------------------------
// Android — splash tầng native: logo vector + màu nền thương hiệu.
// ---------------------------------------------------------------------------

void genNativeSplash() {
  // Khung 144 có lề trong suốt ⇒ không bị cắt khi tầng native hiển thị ở cỡ khác.
  _write(
    '$_androidRes/drawable/splash_logo.xml',
    vectorDrawable(
      viewport: 144,
      dp: 144,
      parts: coinVectorParts(CoinGeometry(144, coinRatioSplash)),
    ),
  );
  // Biến thể cho `windowSplashScreenAnimatedIcon` (Android 12+): nội dung nhỏ
  // hơn để lọt đường tròn mask của hệ thống — xem [coinRatioSplashNative].
  _write(
    '$_androidRes/drawable/splash_logo_masked.xml',
    vectorDrawable(
      viewport: 144,
      dp: 144,
      parts: coinVectorParts(CoinGeometry(144, coinRatioSplashNative)),
    ),
  );
  _write(
    '$_androidRes/values/colors.xml',
    '<?xml version="1.0" encoding="utf-8"?>\n'
        '<resources>\n'
        '    <color name="brand_teal">${_hex(brandTeal)}</color>\n'
        '</resources>\n',
  );
}

// ---------------------------------------------------------------------------
// iOS — icon launcher: ghi đè **đúng tên file** có trong Contents.json ⇒ không
// phải sửa manifest của Xcode. Nền teal **đục** (iOS không nhận PNG trong suốt).
// ---------------------------------------------------------------------------

String get _iosAppIconDir =>
    '$appRoot/ios/Runner/Assets.xcassets/AppIcon.appiconset';

void genIosIcons() {
  final manifest = jsonDecode(File('$_iosAppIconDir/Contents.json').readAsStringSync())
      as Map<String, dynamic>;
  for (final entry in (manifest['images'] as List).cast<Map<String, dynamic>>()) {
    final name = entry['filename'] as String?;
    if (name == null) continue;
    final side = double.parse((entry['size'] as String).split('x').first);
    final scale = int.parse((entry['scale'] as String).replaceAll('x', ''));
    final px = (side * scale).round();
    final png = renderCoin(px, coinRatio: coinRatioIcon, background: brandTeal);
    _writeBytes('$_iosAppIconDir/$name', img.encodePng(png));
  }
}

void main() {
  stdout.writeln('Sinh asset nhận diện (Concept A — Coin Flow) → $appRoot');
  genAndroidIcon();
  genIosIcons();
  genFlutterLogo();
  genNativeSplash();
  genIosLaunchImage();
}
