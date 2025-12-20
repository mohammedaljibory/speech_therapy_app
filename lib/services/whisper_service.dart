import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Result of speech-to-text transcription
class TranscriptionResult {
  final bool success;
  final String? text;
  final String? error;
  final double? confidence;

  TranscriptionResult({
    required this.success,
    this.text,
    this.error,
    this.confidence,
  });
}

/// OpenAI Whisper Service for Speech-to-Text
/// Uses Firebase Functions on Web to avoid CORS issues
class WhisperService {
  /// Transcribe audio file to text
  ///
  /// [audioPath] - Path to the audio file (m4a, mp3, wav, etc.)
  /// [language] - Language code (e.g., 'ar' for Arabic)
  Future<TranscriptionResult> transcribe({
    required String audioPath,
    String language = 'ar',
  }) async {
    if (kIsWeb) {
      return _transcribeViaFirebase(audioPath: audioPath, language: language);
    } else {
      return _transcribeDirect(audioPath: audioPath, language: language);
    }
  }

  /// Transcribe via Firebase Functions (for Web)
  Future<TranscriptionResult> _transcribeViaFirebase({
    required String audioPath,
    String language = 'ar',
  }) async {
    try {
      // For web, we need to send the audio bytes
      // This will be called with bytes from the recording
      return TranscriptionResult(
        success: false,
        error: 'Use transcribeBytes for web platform',
      );
    } catch (e) {
      return TranscriptionResult(success: false, error: e.toString());
    }
  }

  /// Transcribe directly to OpenAI (for Mobile/Desktop)
  Future<TranscriptionResult> _transcribeDirect({
    required String audioPath,
    String language = 'ar',
  }) async {
    if (!ApiConfig.isOpenAiConfigured) {
      return TranscriptionResult(
        success: false,
        error: 'OpenAI API key not configured',
      );
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.whisperDirectUrl),
      );

      request.headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}';

      final file = File(audioPath);
      if (!await file.exists()) {
        return TranscriptionResult(
          success: false,
          error: 'Audio file not found: $audioPath',
        );
      }
      request.files.add(await http.MultipartFile.fromPath('file', audioPath));

      request.fields['model'] = ApiConfig.whisperModel;
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TranscriptionResult(
          success: true,
          text: data['text']?.toString().trim(),
        );
      } else {
        final errorData = json.decode(response.body);
        return TranscriptionResult(
          success: false,
          error: errorData['error']?['message'] ??
              'Unknown error (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return TranscriptionResult(success: false, error: e.toString());
    }
  }

  /// Transcribe audio bytes (works for both Web and Mobile)
  Future<TranscriptionResult> transcribeBytes({
    required List<int> audioBytes,
    required String fileName,
    String language = 'ar',
  }) async {
    try {
      final Uri url;
      final Map<String, String> headers;

      if (kIsWeb) {
        // Use Firebase Functions for Web
        url = Uri.parse(ApiConfig.whisperFunctionUrl);
        headers = {};
      } else {
        // Direct API call for Mobile/Desktop
        if (!ApiConfig.isOpenAiConfigured) {
          return TranscriptionResult(
            success: false,
            error: 'OpenAI API key not configured',
          );
        }
        url = Uri.parse(ApiConfig.whisperDirectUrl);
        headers = {'Authorization': 'Bearer ${ApiConfig.openAiApiKey}'};
      }

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      // Add audio file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: fileName,
      ));

      request.fields['model'] = ApiConfig.whisperModel;
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TranscriptionResult(
          success: data['success'] ?? true,
          text: data['text']?.toString().trim(),
          error: data['error'],
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          return TranscriptionResult(
            success: false,
            error: errorData['error'] ?? 'Unknown error (${response.statusCode})',
          );
        } catch (_) {
          return TranscriptionResult(
            success: false,
            error: 'HTTP ${response.statusCode}: ${response.body}',
          );
        }
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return TranscriptionResult(success: false, error: e.toString());
    }
  }
}
