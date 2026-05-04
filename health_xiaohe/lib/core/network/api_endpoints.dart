class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - use localhost for web, 10.0.2.2 for Android emulator
  static String get baseUrl {
    // Simple platform detection
    return 'http://localhost:8000';
  }

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String me = '/api/auth/me';

  // Health Records
  static const String healthRecords = '/api/health/records';
  static String healthRecord(String id) => '/api/health/records/$id';
  static const String latestRecords = '/api/health/records/latest';

  // Chat
  static const String chat = '/api/consult/chat';
  static const String chatStream = '/api/consult/chat/stream';
  static const String chatHistory = '/api/consult/chat/history';
  static const String conversations = '/api/consult/conversations';
  static String conversationDetail(String id) => '/api/consult/conversations/$id';

  // Voice
  static const String voiceChat = '/api/consult/voice/chat';
  static const String voiceChatStream = '/api/consult/voice/chat/stream';
  static const String voiceWs = '/api/consult/voice/ws';
}
