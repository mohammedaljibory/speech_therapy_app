// IO implementation for mobile/desktop platforms
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// Get temporary directory path for recordings
Future<String> getRecordingPath(String filename) async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}/$filename';
}

/// Read file bytes from disk
Future<Uint8List?> readFileBytes(String path) async {
  final file = File(path);
  if (await file.exists()) {
    return await file.readAsBytes();
  }
  return null;
}

/// Read bytes from blob URL (not used on mobile/desktop)
Future<Uint8List?> readBlobUrl(String blobUrl) async {
  // Not applicable for mobile/desktop
  return null;
}
