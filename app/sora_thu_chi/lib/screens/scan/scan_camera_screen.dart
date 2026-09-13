import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Seam bọc plugin camera/thư viện ảnh — chỉ để test widget màn `scan-02` mà
/// không cần camera thật (R19). Impl thật: [PlatformCameraGateway].
abstract class CameraGateway {
  /// Khởi tạo camera sau (xin quyền **đúng lúc này**, FR-013). `null` = không có
  /// camera hoặc người dùng từ chối quyền — màn chụp vẫn còn đường Thư viện.
  Future<CameraController?> initialize();

  Future<void> setFlashMode(CameraController controller, FlashMode mode);

  /// Chọn ảnh có sẵn trong thư viện; `null` = người dùng huỷ.
  Future<XFile?> pickFromLibrary();
}

/// Impl thật: `availableCameras` + `CameraController` (không bật micro — FR-040)
/// và `image_picker` cho đường thư viện.
class PlatformCameraGateway implements CameraGateway {
  @override
  Future<CameraController?> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      return controller;
    } catch (_) {
      // Từ chối quyền / camera đang bị chiếm → coi như không có camera.
      return null;
    }
  }

  @override
  Future<void> setFlashMode(CameraController controller, FlashMode mode) =>
      controller.setFlashMode(mode);

  @override
  Future<XFile?> pickFromLibrary() =>
      ImagePicker().pickImage(source: ImageSource.gallery);
}

/// Màn chụp hóa đơn (mockup `scan-02`): nền **tối cố định** bất kể theme, khung
/// ngắm nét đứt 4 góc, nút back / flash / Thư viện / chụp tròn. **Không** có nút
/// "Quét nhiều" (FR-016 — quét hàng loạt thuộc GĐ2). Pop trả đường dẫn ảnh.
class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({super.key, this.gateway});

  /// Seam test; mặc định dùng plugin thật.
  final CameraGateway? gateway;

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  late final CameraGateway _gateway = widget.gateway ?? PlatformCameraGateway();

  CameraController? _controller;
  bool _flashOn = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    setState(() => _initializing = true);
    try {
      final controller = await _gateway.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _controller = null;
        _initializing = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = !_flashOn;
    await _gateway.setFlashMode(controller, next ? FlashMode.torch : FlashMode.off);
    if (!mounted) return;
    setState(() => _flashOn = next);
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final shot = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(shot.path);
    } catch (_) {
      if (!mounted) return;
      _showError('Không chụp được ảnh. Vui lòng thử lại.');
    }
  }

  Future<void> _pickFromLibrary() async {
    final picked = await _gateway.pickFromLibrary();
    if (!mounted || picked == null) return;
    Navigator.of(context).pop(picked.path);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.tr)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nền tối cố định (FR-040): không đọc token theme ở đây.
    return Scaffold(
      key: const ValueKey('scan-camera-screen'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Quét hóa đơn'.tr),
        actions: [
          IconButton(
            key: const ValueKey('scan-flash'),
            tooltip: 'Bật/tắt đèn flash'.tr,
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _controller == null ? null : _toggleFlash,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _preview(),
          CustomPaint(
            key: const ValueKey('scan-guide-overlay'),
            painter: _GuideFramePainter(),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Đặt hóa đơn vừa khung, tránh bóng đổ'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _bottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final controller = _controller;
    if (_initializing) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Không mở được camera. Bạn vẫn có thể chọn ảnh từ thư viện.'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      );
    }
    return CameraPreview(controller);
  }

  /// Hàng dưới: Thư viện (trái) · nút chụp tròn (giữa). Không có "Quét nhiều".
  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            key: const ValueKey('scan-library'),
            onPressed: _pickFromLibrary,
            icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
            label: Text(
              'Thư viện'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Semantics(
            button: true,
            label: 'Chụp ảnh'.tr,
            child: InkWell(
              key: const ValueKey('scan-shutter'),
              onTap: _controller == null ? null : _capture,
              customBorder: const CircleBorder(),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          // Giữ chỗ đối xứng với nút Thư viện — mockup không có nút thứ ba.
          const SizedBox(width: 88),
        ],
      ),
    );
  }
}

/// Khung ngắm nét đứt 4 góc (mockup `scan-02`) — vẽ trực tiếp, không asset.
class _GuideFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.78,
      height: size.height * 0.4,
    );
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const arm = 26.0;
    final corners = [
      [rect.topLeft, const Offset(arm, 0), const Offset(0, arm)],
      [rect.topRight, const Offset(-arm, 0), const Offset(0, arm)],
      [rect.bottomLeft, const Offset(arm, 0), const Offset(0, -arm)],
      [rect.bottomRight, const Offset(-arm, 0), const Offset(0, -arm)],
    ];
    for (final corner in corners) {
      final origin = corner[0];
      canvas.drawLine(origin, origin + corner[1], paint);
      canvas.drawLine(origin, origin + corner[2], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideFramePainter oldDelegate) => false;
}
