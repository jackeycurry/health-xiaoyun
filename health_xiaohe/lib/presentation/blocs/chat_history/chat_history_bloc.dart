import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';
import 'chat_history_event.dart';
import 'chat_history_state.dart';

class ChatHistoryBloc extends Bloc<ChatHistoryEvent, ChatHistoryState> {
  final ChatRepository _chatRepository;

  ChatHistoryBloc(this._chatRepository) : super(const ChatHistoryState()) {
    on<ChatHistoryLoadConversations>(_onLoadConversations);
    on<ChatHistoryLoadConversationDetail>(_onLoadConversationDetail);
  }

  Future<void> _onLoadConversations(
    ChatHistoryLoadConversations event,
    Emitter<ChatHistoryState> emit,
  ) async {
    emit(state.copyWith(status: ChatHistoryStatus.loading));
    final result = await _chatRepository.getConversations();
    if (result.success) {
      emit(state.copyWith(
        status: ChatHistoryStatus.success,
        conversations: result.data!,
      ));
    } else {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: result.error,
      ));
    }
  }

  Future<void> _onLoadConversationDetail(
    ChatHistoryLoadConversationDetail event,
    Emitter<ChatHistoryState> emit,
  ) async {
    emit(state.copyWith(status: ChatHistoryStatus.loading, selectedConversation: null));
    final result = await _chatRepository.getConversationDetail(event.conversationId);
    if (result.success) {
      emit(state.copyWith(
        status: ChatHistoryStatus.success,
        selectedConversation: result.data!,
      ));
    } else {
      emit(state.copyWith(
        status: ChatHistoryStatus.error,
        error: result.error,
      ));
    }
  }
}
