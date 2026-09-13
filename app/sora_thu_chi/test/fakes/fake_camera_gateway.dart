import 'package:camera/camera.dart';

import 'package:sora_thu_chi/screens/scan/scan_camera_screen.dart';

/// Fake [CameraGateway] — không cần camera thật trong widget test.
/// [controller] null = không có camera/bị từ chối quyền (màn chụp hiện nền tối
/// + thông báo, vẫn còn đường Thư viện). [libraryPath] là ảnh "chọn từ thư viện".
class FakeCameraGateway implements CameraGateway {
  FakeCameraGateway({this.controller, this.libraryPath, this.initError});

  CameraController? controller;
  String? libraryPath;
  Object? initError;

  int initCount = 0;
  int libraryCount = 0;
  final List<FlashMode> flashModes = [];

  @override
  Future<CameraController?> initialize() async {
    initCount++;
    if (initError != null) throw initError!;
    return controller;
  }

  @override
  Future<void> setFlashMode(CameraController controller, FlashMode mode) async {
    flashModes.add(mode);
  }

  @override
  Future<XFile?> pickFromLibrary() async {
    libraryCount++;
    final path = libraryPath;
    return path == null ? null : XFile(path);
  }
}
