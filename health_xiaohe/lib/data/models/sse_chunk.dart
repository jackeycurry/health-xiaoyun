class SseChunk {
  final String? content;
  final String? conversationId;
  final List<String>? suggestions;

  const SseChunk({this.content, this.conversationId, this.suggestions});

  bool get hasContent => content != null && content!.isNotEmpty;
  bool get hasConversationId => conversationId != null && conversationId!.isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
}
