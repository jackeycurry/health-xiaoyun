import 'dart:async';
import 'package:health_xiaohe/data/models/chat_message_model.dart';
import 'package:health_xiaohe/data/models/conversation_model.dart';
import 'package:health_xiaohe/data/models/sse_chunk.dart';

abstract class ChatRepository {
  Stream<SseChunk> getChatStream(List<ChatMessageModel> messages, {String? conversationId});
  Future<ChatResult<ChatMessageModel>> sendMessage(List<ChatMessageModel> messages);
  Future<ChatResult<List<ConversationItemModel>>> getConversations();
  Future<ChatResult<ConversationDetailModel>> getConversationDetail(String id);
  Future<ChatResult<void>> deleteConversation(String id);
  Future<ChatResult<List<String>>> getWelcomeSuggestions();
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
