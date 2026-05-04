import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';

class ChatState extends Equatable {
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;
  final String? conversationId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.conversationId,
  });

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
    String? conversationId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, conversationId];
}
