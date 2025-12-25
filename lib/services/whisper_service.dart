import 'dart:convert';
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
    // On web, use transcribeBytes instead
    if (kIsWeb) {
      return TranscriptionResult(
        success: false,
        error: 'Use transcribeBytes for web platform',
      );
    }

    // For mobile/desktop, this method requires platform-specific implementation
    return TranscriptionResult(
      success: false,
      error: 'Use transcribeBytes method instead',
    );
  }

  /// Transcribe audio bytes (works for both Web and Mobile)
  Future<TranscriptionResult> transcribeBytes({
    required List<int> audioBytes,
    required String fileName,
    String language = 'ar',
  }) async {
    try {
      if (kIsWeb) {
        // Use Firebase Functions for Web - send as base64 JSON
        final url = Uri.parse(ApiConfig.whisperFunctionUrl);
        final base64Audio = base64Encode(audioBytes);

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'audio': base64Audio,
            'fileName': fileName,
            'language': language,
          }),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return TranscriptionResult(
            success: data['success'] ?? true,
            text: data['text']?.toString().trim(),
            error: data['error']?.toString(),
          );
        } else {
          try {
            final errorData = json.decode(response.body);
            return TranscriptionResult(
              success: false,
              error: errorData['error']?.toString() ?? 'Unknown error (${response.statusCode})',
            );
          } catch (_) {
            return TranscriptionResult(
              success: false,
              error: 'HTTP ${response.statusCode}: ${response.body}',
            );
          }
        }
      } else {
        // Direct API call for Mobile/Desktop using multipart
        if (!ApiConfig.isOpenAiConfigured) {
          return TranscriptionResult(
            success: false,
            error: 'OpenAI API key not configured',
          );
        }

        final url = Uri.parse(ApiConfig.whisperDirectUrl);
        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}';

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
            success: true,
            text: data['text']?.toString().trim(),
          );
        } else {
          try {
            final errorData = json.decode(response.body);
            return TranscriptionResult(
              success: false,
              error: errorData['error']?['message']?.toString() ?? 'Unknown error',
            );
          } catch (_) {
            return TranscriptionResult(
              success: false,
              error: 'HTTP ${response.statusCode}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return TranscriptionResult(success: false, error: e.toString());
    }
  }
}
