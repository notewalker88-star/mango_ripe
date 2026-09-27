import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'storage_helper/storage_helper.dart';

class ImageUtils {
  static final StorageHelper _storage = getStorageHelper();

  /// Crops image to a square center crop and downsizes to a fast working resolution (max 512x512)
  static Future<Uint8List> centerCropAsync(Uint8List imageBytes) async {
    if (kIsWeb) {
      return _cropAndResize(imageBytes);
    } else {
      return compute(_cropAndResize, imageBytes);
    }
  }

  static Uint8List _cropAndResize(Uint8List imageBytes) {
    try {
      final img.Image? source = img.decodeImage(imageBytes);
      if (source == null) return imageBytes;

      final size = source.width < source.height ? source.width : source.height;
      final x = (source.width - size) ~/ 2;
      final y = (source.height - size) ~/ 2;

      var cropped = img.copyCrop(source, x: x, y: y, width: size, height: size);
      if (cropped.width > 512) {
        cropped = img.copyResize(
          cropped,
          width: 512,
          height: 512,
          interpolation: img.Interpolation.linear,
        );
      }
      return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
    } catch (_) {
      return imageBytes;
    }
  }

  /// Backward-compatible synchronous version
  static Uint8List centerCrop(Uint8List imageBytes) => _cropAndResize(imageBytes);

  /// Saves a thumbnail of the image and returns either a local path or a base64 data URI
  static Future<String?> saveThumbnail(Uint8List imageBytes, String id) async {
    try {
      Uint8List encodedJpg;
      if (kIsWeb) {
        encodedJpg = _generateThumbnailBytes(imageBytes);
      } else {
        encodedJpg = await compute(_generateThumbnailBytes, imageBytes);
      }
      if (encodedJpg.isEmpty) return null;
      return await _storage.saveThumbnailFile(encodedJpg, id);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _generateThumbnailBytes(Uint8List imageBytes) {
    try {
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) return Uint8List(0);

      final thumbnail = img.copyResize(
        decoded,
        width: 140,
        height: 140,
        interpolation: img.Interpolation.linear,
      );
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 75));
    } catch (_) {
      return Uint8List(0);
    }
  }
}
