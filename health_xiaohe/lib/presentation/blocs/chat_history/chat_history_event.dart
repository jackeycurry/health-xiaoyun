import 'package:equatable/equatable.dart';

abstract class ChatHistoryEvent extends Equatable {
  const ChatHistoryEvent();

  @override
  List<Object?> get props => [];
}

class ChatHistoryLoadConversations extends ChatHistoryEvent {}

class ChatHistoryLoadConversationDetail extends ChatHistoryEvent {
  final String conversationId;

  const ChatHistoryLoadConversationDetail(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}
