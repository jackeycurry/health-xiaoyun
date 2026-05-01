import 'package:equatable/equatable.dart';

abstract class VoiceState extends Equatable {
  const VoiceState();

  @override
  List<Object?> get props => [];
}

class VoiceInitial extends VoiceState {}

class VoiceConnecting extends VoiceState {}

class VoiceConnected extends VoiceState {}

class VoiceDisconnected extends VoiceState {}

class VoiceRecording extends VoiceState {
  final Duration duration;

  const VoiceRecording({this.duration = Duration.zero});

  @override
  List<Object?> get props => [duration];
}

class VoiceProcessing extends VoiceState {}

class VoiceReceivingText extends VoiceState {
  final String text;

  const VoiceReceivingText(this.text);

  @override
  List<Object?> get props => [text];
}

class VoiceReceivingAudio extends VoiceState {
  final String audioData;

  const VoiceReceivingAudio(this.audioData);

  @override
  List<Object?> get props => [audioData];
}

class VoiceDone extends VoiceState {}

class VoiceErrorState extends VoiceState {
  final String message;

  const VoiceErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
