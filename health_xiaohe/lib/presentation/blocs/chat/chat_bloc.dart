import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<String>? _streamSubscription;

  ChatBloc(this._chatRepository) : super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatReceiveStreamChunk>(_onReceiveChunk);
    on<ChatStreamCompleted>(_onStreamCompleted);
    on<ChatStreamError>(_onStreamError);
    on<ChatClearMessages>(_onClearMessages);
  }

  void _onInitialize(ChatInitialize event, Emitter<ChatState> emit) {
    if (state.messages.isEmpty) {
      final welcomeMessage = ChatMessageModel.assistant(
        '你好！我是健康小荷，你的健康管家~ 有什么健康问题可以问我哦！',
      );
      emit(state.copyWith(messages: [welcomeMessage]));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Add user message
    final userMsg = ChatMessageModel.user(event.message);
    final updatedMessages = [...state.messages, userMsg];
    emit(state.copyWith(messages: updatedMessages, isLoading: true, error: null));

    // Create assistant message placeholder
    final assistantMsg = ChatMessageModel.assistant('');
    final messagesWithAssistant = [...updatedMessages, assistantMsg];
    emit(state.copyWith(messages: messagesWithAssistant));

    try {
      final stream = _chatRepository.getChatStream(updatedMessages);

      _streamSubscription?.cancel();
      _streamSubscription = stream.listen(
        (chunk) {
          add(ChatReceiveStreamChunk(chunk));
        },
        onError: (error) {
          add(ChatStreamError(error.toString()));
        },
        onDone: () {
          add(ChatStreamCompleted());
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
        messages: updatedMessages,
      ));
    }
  }

  void _onReceiveChunk(ChatReceiveStreamChunk event, Emitter<ChatState> emit) {
    final updatedMessages = [...state.messages];

    if (updatedMessages.isNotEmpty && updatedMessages.last.isAssistant) {
      // Append to last assistant message
      final lastMsg = updatedMessages.removeLast();
      final updatedContent = lastMsg.content + event.chunk;
      updatedMessages.add(lastMsg.copyWith(content: updatedContent));
    } else if (event.chunk.isNotEmpty) {
      // Create new assistant message
      updatedMessages.add(ChatMessageModel.assistant(event.chunk));
    }

    emit(state.copyWith(messages: updatedMessages, isLoading: false));
  }

  void _onStreamCompleted(ChatStreamCompleted event, Emitter<ChatState> emit) {
    emit(state.copyWith(isLoading: false));
  }

  void _onStreamError(ChatStreamError event, Emitter<ChatState> emit) {
    // Remove the empty assistant message if there's an error
    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isAssistant && messages.last.content.isEmpty) {
      messages.removeLast();
    }
    emit(state.copyWith(messages: messages, isLoading: false, error: event.error));
  }

  void _onClearMessages(ChatClearMessages event, Emitter<ChatState> emit) {
    final welcomeMessage = ChatMessageModel.assistant(
      '你好！我是健康小荷，你的健康管家~ 有什么健康问题可以问我哦！',
    );
    emit(ChatState(messages: [welcomeMessage]));
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
