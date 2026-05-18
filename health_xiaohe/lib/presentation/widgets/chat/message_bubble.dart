import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isStreaming;

  const MessageBubble({super.key, required this.message, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    final child = message.isUser
        ? UserMessageBubble(message: message)
        : AiMessageBubble(message: message, isStreaming: isStreaming);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, c) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class AiMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isStreaming;

  const AiMessageBubble({super.key, required this.message, this.isStreaming = false});

  static final _styleSheet = MarkdownStyleSheet(
    h1: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    h2: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    h3: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    p: const TextStyle(
      fontSize: 16,
      color: AppColors.textSecondary,
      height: 1.5,
    ),
    strong: const TextStyle(
      fontWeight: FontWeight.w600,
      color: AppColors.secondary,
    ),
    em: const TextStyle(fontStyle: FontStyle.italic),
    code: const TextStyle(
      backgroundColor: Color(0x0F000000),
      fontSize: 14,
      fontFamily: 'monospace',
    ),
    codeblockDecoration: BoxDecoration(
      color: const Color(0x0A000000),
      borderRadius: BorderRadius.circular(8),
    ),
    blockquoteDecoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
      border: const Border(
        left: BorderSide(color: AppColors.primary, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(
        top: BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    listBullet: const TextStyle(
      fontSize: 16,
      color: AppColors.textSecondary,
    ),
    tableBody: const TextStyle(
      fontSize: 14,
      color: AppColors.textSecondary,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.aiBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: AppColors.aiBubbleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content.isNotEmpty)
                    MarkdownBody(
                      data: message.content,
                      styleSheet: _styleSheet,
                      selectable: true,
                    ),
                  if (isStreaming)
                    Padding(
                      padding: EdgeInsets.only(top: message.content.isEmpty ? 4 : 2),
                      child: const _BlinkingCursor(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (message.timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp!),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class UserMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const UserMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('HH:mm').format(message.timestamp!),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: AppColors.userBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (message.hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        message.imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  if (message.hasImage && message.content.isNotEmpty)
                    const SizedBox(height: 8),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: AppColors.userBubbleText,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
