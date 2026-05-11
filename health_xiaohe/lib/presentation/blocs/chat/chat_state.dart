import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';

class ChatState extends Equatable {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;
  final String? conversationId;
  final List<String> suggestions; // AI 推荐的追问

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.conversationId,
    this.suggestions = const [],
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
    String? conversationId,
    List<String>? suggestions,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversationId: conversationId ?? this.conversationId,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, conversationId, suggestions];
}
