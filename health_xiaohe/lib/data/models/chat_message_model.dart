import 'dart:convert';
import 'dart:typed_data';

class ChatMessageModel {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;
  final Uint8List? imageBytes; // 图片数据

  ChatMessageModel({
    required this.role,
    required this.content,
    this.timestamp,
    this.imageBytes,
  });

  factory ChatMessageModel.user(String content, {Uint8List? imageBytes}) {
    return ChatMessageModel(
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
      imageBytes: imageBytes,
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
  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  Map<String, dynamic> toApiFormat() {
    final map = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (hasImage) {
      map['image'] = base64Encode(imageBytes!);
    }
    return map;
  }

  ChatMessageModel copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    Uint8List? imageBytes,
  }) {
    return ChatMessageModel(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}
