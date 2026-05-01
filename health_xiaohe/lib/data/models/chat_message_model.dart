class ChatMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;

  ChatMessageModel({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory ChatMessageModel.user(String content) {
    return ChatMessageModel(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessageModel.assistant(String content) {
    return ChatMessageModel(
      role: 'assistant',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessageModel.system(String content) {
    return ChatMessageModel(
      role: 'system',
      content: content,
      timestamp: DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

  Map<String, String> toApiFormat() {
    return {
      'role': role,
      'content': content,
    };
  }

  ChatMessageModel copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
