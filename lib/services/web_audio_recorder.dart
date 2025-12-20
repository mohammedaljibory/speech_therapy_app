import 'dart:async';
import 'package:flutter/foundation.dart';

// For web, we'll use a simple approach with just recording
// Speech recognition will be handled separately

/// Platform-agnostic audio recorder service
class AudioRecorderService {
  bool _isRecording = false;
  String? _recordingPath;
  String? _transcription;
  int _recordingStartTime = 0;

  bool get isRecording => _isRecording;
  String? get recordingPath => _recordingPath;
  String? get transcription => _transcription;

  /// Check if has permission
  Future<bool> hasPermission() async {
    // On web, permission is requested when recording starts
    return true;
  }

  /// Start recording
  Future<bool> startRecording() async {
    try {
      _isRecording = true;
      _recordingStartTime = DateTime.now().millisecondsSinceEpoch;
      _transcription = null;
      debugPrint('Recording started (simulated for web)');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording
  Future<String?> stopRecording() async {
    _isRecording = false;

    // Generate a fake recording path for now
    // In production, this would be a blob URL from MediaRecorder
    _recordingPath = 'recording_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('Recording stopped');
    return _recordingPath;
  }

  /// Cancel recording
  void cancelRecording() {
    _isRecording = false;
    _recordingPath = null;
    _transcription = null;
  }

  /// Set transcription manually (for testing)
  void setTranscription(String text) {
    _transcription = text;
  }

  /// Dispose
  void dispose() {
    cancelRecording();
  }
}