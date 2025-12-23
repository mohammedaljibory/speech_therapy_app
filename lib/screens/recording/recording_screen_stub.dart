// Stub implementation for web platform
import 'dart:typed_data';

/// Get temporary directory path (not available on web)
Future<String> getRecordingPath(String filename) async {
  return filename;
}

/// Read file bytes (web implementation using http)
Future<Uint8List?> readFileBytes(String path) async {
  // On web, we'll handle this differently
  return null;
}

/// Read bytes from blob URL (web-specific)
Future<Uint8List?> readBlobUrl(String blobUrl) async {
  // Web implementation - blob URLs are handled by the browser
  return null;
}
