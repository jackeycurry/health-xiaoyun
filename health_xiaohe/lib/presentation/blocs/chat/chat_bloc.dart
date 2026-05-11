import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';
import 'package:health_xiaohe/data/models/sse_chunk.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<SseChunk>? _streamSubscription;

  ChatBloc(this._chatRepository) : super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatReceiveStreamChunk>(_onReceiveChunk);
    on<ChatStreamCompleted>(_onStreamCompleted);
    on<ChatStreamError>(_onStreamError);
    on<ChatClearMessages>(_onClearMessages);
    on<ChatNewConversation>(_onNewConversation);
    on<ChatLoadConversation>(_onLoadConversation);
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
    final imageBytes = event.imageBytes != null ? Uint8List.fromList(event.imageBytes!) : null;
    final userMsg = ChatMessageModel.user(event.message, imageBytes: imageBytes);
    final updatedMessages = [...state.messages, userMsg];
    emit(state.copyWith(messages: updatedMessages, isLoading: true, error: null, suggestions: []));

    final assistantMsg = ChatMessageModel.assistant('');
    final messagesWithAssistant = [...updatedMessages, assistantMsg];
    emit(state.copyWith(messages: messagesWithAssistant));

    try {
      final stream = _chatRepository.getChatStream(
        updatedMessages,
        conversationId: state.conversationId,
      );

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
    final chunk = event.chunk;

    // 处理追问建议
    if (chunk.hasSuggestions) {
      emit(state.copyWith(suggestions: chunk.suggestions));
      return;
    }

    // 处理 conversation_id
    if (chunk.hasConversationId && chunk.conversationId != null) {
      emit(state.copyWith(conversationId: chunk.conversationId));
      return;
    }

    // 处理内容追加
    if (chunk.hasContent) {
      final content = chunk.content!;
      final updatedMessages = [...state.messages];
      if (updatedMessages.isNotEmpty && updatedMessages.last.isAssistant) {
        final lastMsg = updatedMessages.removeLast();
        updatedMessages.add(lastMsg.copyWith(content: lastMsg.content + content));
      } else {
        updatedMessages.add(ChatMessageModel.assistant(content));
      }
      emit(state.copyWith(messages: updatedMessages, isLoading: false));
    }
  }

  void _onStreamCompleted(ChatStreamCompleted event, Emitter<ChatState> emit) {
    emit(state.copyWith(isLoading: false));
  }

  void _onStreamError(ChatStreamError event, Emitter<ChatState> emit) {
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

  void _onNewConversation(ChatNewConversation event, Emitter<ChatState> emit) {
    final welcomeMessage = ChatMessageModel.assistant(
      '你好！我是健康小荷，你的健康管家~ 有什么健康问题可以问我哦！',
    );
    emit(ChatState(messages: [welcomeMessage], suggestions: []));
  }

  Future<void> _onLoadConversation(
    ChatLoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await _chatRepository.getConversationDetail(event.conversationId);
    if (result.success) {
      final detail = result.data!;
      final messages = detail.messages.map((m) {
        return ChatMessageModel(
          role: m.role,
          content: m.content,
          timestamp: m.createdAt,
        );
      }).toList();
      emit(ChatState(
        messages: messages,
        conversationId: event.conversationId,
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        error: result.error,
      ));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
