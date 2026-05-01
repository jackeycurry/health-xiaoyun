import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return UserMessageBubble(message: message);
    } else {
      return AiMessageBubble(message: message);
    }
  }
}

class AiMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const AiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
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
          // Bubble
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
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Timestamp
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
          // Timestamp
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
          // Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.userBubbleBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.userBubbleText,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
