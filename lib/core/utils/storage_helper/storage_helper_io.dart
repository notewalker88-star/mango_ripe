import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'storage_helper_interface.dart';

StorageHelper getStorageHelper() => StorageHelperIO();

class StorageHelperIO implements StorageHelper {
  @override
  Future<String?> saveThumbnailFile(Uint8List bytes, String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbDir = Directory('${dir.path}/thumbnails');
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }
      final path = '${thumbDir.path}/$id.jpg';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    } catch (_) {
      return null;
    }
  }
}
