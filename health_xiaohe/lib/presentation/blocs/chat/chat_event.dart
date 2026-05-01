import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatSendMessage extends ChatEvent {
  final String message;

  const ChatSendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatReceiveStreamChunk extends ChatEvent {
  final String chunk;

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
