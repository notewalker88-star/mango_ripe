import 'dart:convert';
import 'dart:typed_data';
import 'storage_helper_interface.dart';

StorageHelper getStorageHelper() => StorageHelperWeb();

class StorageHelperWeb implements StorageHelper {
  @override
  Future<String?> saveThumbnailFile(Uint8List bytes, String id) async {
    // In web, return as base64 data URI
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
