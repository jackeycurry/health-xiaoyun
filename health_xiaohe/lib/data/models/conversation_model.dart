class ConversationItemModel {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationItemModel({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationItemModel.fromJson(Map<String, dynamic> json) {
    return ConversationItemModel(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class ConversationDetailModel {
  final String id;
  final String title;
  final List<ConversationMessageModel> messages;
  final DateTime createdAt;

  ConversationDetailModel({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  factory ConversationDetailModel.fromJson(Map<String, dynamic> json) {
    return ConversationDetailModel(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => ConversationMessageModel.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ConversationMessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  ConversationMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ConversationMessageModel.fromJson(Map<String, dynamic> json) {
    return ConversationMessageModel(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
