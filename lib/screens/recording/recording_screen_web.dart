// Web implementation using dart:html for blob URL handling
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

/// HTML5 Audio element for web playback
html.AudioElement? _audioElement;

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

/// Play audio using HTML5 Audio element (web-specific)
/// This is more reliable than audioplayers on web
Future<bool> playAudioWeb(String url) async {
  try {
    print('Playing audio via HTML5 Audio: $url');

    // Stop any existing audio
    stopAudioWeb();

    // Method 1: Fetch as blob and create blob URL to avoid CORS issues
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'blob',
      );

      if (response.status == 200) {
        final blob = response.response as html.Blob;
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        print('Created blob URL: $blobUrl from ${blob.size} bytes');

        _audioElement = html.AudioElement(blobUrl);
        await _audioElement!.play();
        print('HTML5 Audio playback started via blob URL');
        return true;
      }
    } catch (fetchError) {
      print('Blob fetch failed: $fetchError, trying direct URL...');
    }

    // Method 2: Try direct URL playback
    _audioElement = html.AudioElement();
    _audioElement!.src = url;
    _audioElement!.preload = 'auto';

    try {
      await _audioElement!.play();
      print('HTML5 Audio playback started via direct URL');
      return true;
    } catch (playError) {
      print('Direct play failed: $playError');

      // Method 3: Wait for canPlayThrough
      final completer = Completer<bool>();
      var completed = false;

      _audioElement!.onCanPlayThrough.first.then((_) {
        if (!completed) {
          completed = true;
          _audioElement!.play();
          print('HTML5 Audio playback started after load');
          completer.complete(true);
        }
      });

      _audioElement!.onError.first.then((event) {
        if (!completed) {
          completed = true;
          print('HTML5 Audio error: ${_audioElement!.error?.code} - ${_audioElement!.error?.message}');
          completer.complete(false);
        }
      });

      _audioElement!.load();

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('HTML5 Audio timeout');
          return false;
        },
      );
    }
  } catch (e) {
    print('Error playing audio via HTML5: $e');
    return false;
  }
}

/// Stop HTML5 audio playback
void stopAudioWeb() {
  if (_audioElement != null) {
    _audioElement!.pause();
    _audioElement!.src = '';
    _audioElement = null;
  }
}
