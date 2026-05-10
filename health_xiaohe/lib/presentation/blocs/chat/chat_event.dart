import 'package:equatable/equatable.dart';
import 'package:health_xiaohe/data/models/sse_chunk.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatSendMessage extends ChatEvent {
  final String message;
  final List<int>? imageBytes;

  const ChatSendMessage(this.message, {this.imageBytes});

  @override
  List<Object?> get props => [message, imageBytes];
}

class ChatReceiveStreamChunk extends ChatEvent {
  final SseChunk chunk;

  const ChatReceiveStreamChunk(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

class ChatStreamCompleted extends ChatEvent {}

class ChatStreamError extends ChatEvent {
  final String error;

  const ChatStreamError(this.error);

  @override
  List<Object?> get props => [error];
}

class ChatClearMessages extends ChatEvent {}

class ChatInitialize extends ChatEvent {}

class ChatNewConversation extends ChatEvent {}

class ChatLoadConversation extends ChatEvent {
  final String conversationId;

  const ChatLoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}
