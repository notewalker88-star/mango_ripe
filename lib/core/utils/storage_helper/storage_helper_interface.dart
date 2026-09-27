import 'dart:typed_data';

abstract class StorageHelper {
  Future<String?> saveThumbnailFile(Uint8List bytes, String id);
}
