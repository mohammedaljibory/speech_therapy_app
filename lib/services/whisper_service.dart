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
class WhisperService {
  /// Transcribe audio file to text using OpenAI Whisper API
  ///
  /// [audioPath] - Path to the audio file (m4a, mp3, wav, etc.)
  /// [language] - Language code (e.g., 'ar' for Arabic)
  Future<TranscriptionResult> transcribe({
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
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.whisperEndpoint),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}';

      // Add file
      if (kIsWeb) {
        // For web, we need to handle differently
        // The audio bytes should be passed directly
        return TranscriptionResult(
          success: false,
          error: 'Web platform requires different handling. Use transcribeBytes instead.',
        );
      } else {
        final file = File(audioPath);
        if (!await file.exists()) {
          return TranscriptionResult(
            success: false,
            error: 'Audio file not found: $audioPath',
          );
        }
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          audioPath,
        ));
      }

      // Add model and language
      request.fields['model'] = ApiConfig.whisperModel;
      request.fields['language'] = language;
      request.fields['response_format'] = 'json';

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout');
        },
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
          error: errorData['error']?['message'] ?? 'Unknown error (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return TranscriptionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Transcribe audio bytes directly (useful for web platform)
  Future<TranscriptionResult> transcribeBytes({
    required List<int> audioBytes,
    required String fileName,
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
        Uri.parse(ApiConfig.whisperEndpoint),
      );

      request.headers['Authorization'] = 'Bearer ${ApiConfig.openAiApiKey}';

      // Add audio bytes as file
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
        final errorData = json.decode(response.body);
        return TranscriptionResult(
          success: false,
          error: errorData['error']?['message'] ?? 'Unknown error (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Whisper transcription error: $e');
      return TranscriptionResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
