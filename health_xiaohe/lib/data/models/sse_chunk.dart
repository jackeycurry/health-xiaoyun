class SseChunk {
  final String? content;
  final String? conversationId;

  const SseChunk({this.content, this.conversationId});

  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasConversationId =>
      conversationId != null && conversationId!.isNotEmpty;
}
