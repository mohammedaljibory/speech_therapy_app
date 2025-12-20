/// API Configuration for external services
///
/// For WEB: Uses Firebase Cloud Functions as proxy (to avoid CORS)
/// For Mobile/Desktop: Can call APIs directly
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Firebase Project ID (from your Firebase config)
  static const String firebaseProjectId = 'speech-therapy-app-14ba5';
  static const String firebaseRegion = 'us-central1';

  // Firebase Functions URLs (for Web - avoids CORS)
  static String get functionsBaseUrl =>
      'https://$firebaseRegion-$firebaseProjectId.cloudfunctions.net';

  static String get whisperFunctionUrl => '$functionsBaseUrl/whisperTranscribe';
  static String get claudeFunctionUrl => '$functionsBaseUrl/claudeEvaluate';
  static String get healthCheckUrl => '$functionsBaseUrl/healthCheck';

  // Direct API URLs (for Mobile/Desktop)
  static const String whisperDirectUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String claudeDirectUrl =
      'https://api.anthropic.com/v1/messages';

  // API Keys (only used for Mobile/Desktop direct calls)
  // For Web, keys are stored in Firebase Functions config
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY';

  // Model configurations
  static const String whisperModel = 'whisper-1';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const String claudeApiVersion = '2023-06-01';

  // Use Firebase Functions for Web, direct API for others
  static bool get useFirebaseFunctions => kIsWeb;

  // Check if configured
  static bool get isOpenAiConfigured =>
      kIsWeb || (openAiApiKey.isNotEmpty && !openAiApiKey.startsWith('YOUR_'));

  static bool get isClaudeConfigured =>
      kIsWeb || (claudeApiKey.isNotEmpty && !claudeApiKey.startsWith('YOUR_'));

  static bool get isFullyConfigured => isOpenAiConfigured && isClaudeConfigured;
}
