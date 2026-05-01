import 'dart:async';
import 'package:health_xiaohe/data/models/chat_message_model.dart';

abstract class ChatRepository {
  Stream<String> getChatStream(List<ChatMessageModel> messages);
  Future<ChatResult<ChatMessageModel>> sendMessage(List<ChatMessageModel> messages);
}

class ChatResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ChatResult.success(this.data)
      : success = true,
        error = null;

  ChatResult.failure(this.error)
      : success = false,
        data = null;
}
