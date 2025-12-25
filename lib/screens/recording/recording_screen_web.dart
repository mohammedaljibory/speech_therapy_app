// Web implementation using dart:html for blob URL handling
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

/// Get temporary directory path (not used on web)
Future<String> getRecordingPath(String filename) async {
  return filename;
}

/// Read file bytes from path (not used on web for recordings)
Future<Uint8List?> readFileBytes(String path) async {
  // On web, blob URLs should be handled by readBlobUrl
  return null;
}

/// Read bytes from blob URL (web-specific implementation)
/// Uses the browser's Fetch API to read blob URL data
Future<Uint8List?> readBlobUrl(String blobUrl) async {
  try {
    print('Reading blob URL: $blobUrl');

    // Use XMLHttpRequest for better compatibility with blob URLs
    final completer = Completer<Uint8List?>();

    final xhr = html.HttpRequest();
    xhr.open('GET', blobUrl);
    xhr.responseType = 'arraybuffer';

    xhr.onLoad.listen((event) {
      if (xhr.status == 200) {
        final buffer = xhr.response as ByteBuffer;
        final bytes = buffer.asUint8List();
        print('Successfully read ${bytes.length} bytes from blob URL');
        completer.complete(bytes);
      } else {
        print('Failed to read blob URL: HTTP ${xhr.status}');
        completer.complete(null);
      }
    });

    xhr.onError.listen((event) {
      print('Error reading blob URL via XHR');
      completer.complete(null);
    });

    xhr.send();

    return await completer.future;
  } catch (e) {
    print('Error reading blob URL: $e');
    return null;
  }
}
