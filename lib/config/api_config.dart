/// API Configuration for external services
///
/// IMPORTANT: In production, these keys should be stored securely
/// (e.g., environment variables, secure storage, or backend proxy)
class ApiConfig {
  // OpenAI API Configuration
  static const String openAiApiKey = 'YOUR_OPENAI_API_KEY';
  static const String whisperEndpoint = 'https://api.openai.com/v1/audio/transcriptions';
  static const String whisperModel = 'whisper-1';

  // Anthropic Claude API Configuration
  static const String claudeApiKey = 'YOUR_CLAUDE_API_KEY';
  static const String claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  static const String claudeModel = 'claude-sonnet-4-20250514';
  static const String claudeApiVersion = '2023-06-01';

  // Check if API keys are configured
  static bool get isOpenAiConfigured =>
      openAiApiKey.isNotEmpty && !openAiApiKey.startsWith('YOUR_');

  static bool get isClaudeConfigured =>
      claudeApiKey.isNotEmpty && !claudeApiKey.startsWith('YOUR_');

  static bool get isFullyConfigured => isOpenAiConfigured && isClaudeConfigured;
}
