import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/conversation_model.dart';

enum ChatHistoryStatus { initial, loading, success, error }

class ChatHistoryState extends Equatable {
  final ChatHistoryStatus status;
  final List<ConversationItemModel> conversations;
  final ConversationDetailModel? selectedConversation;
  final String? error;

  const ChatHistoryState({
    this.status = ChatHistoryStatus.initial,
    this.conversations = const [],
    this.selectedConversation,
    this.error,
  });

  ChatHistoryState copyWith({
    ChatHistoryStatus? status,
    List<ConversationItemModel>? conversations,
    ConversationDetailModel? selectedConversation,
    String? error,
  }) {
    return ChatHistoryState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      selectedConversation: selectedConversation ?? this.selectedConversation,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, conversations, selectedConversation, error];
}
