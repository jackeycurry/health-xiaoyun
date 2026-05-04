import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_event.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_state.dart';

class ConversationDetailPage extends StatefulWidget {
  final String conversationId;

  const ConversationDetailPage({super.key, required this.conversationId});

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatHistoryBloc>().add(
          ChatHistoryLoadConversationDetail(widget.conversationId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: BlocBuilder<ChatHistoryBloc, ChatHistoryState>(
          builder: (context, state) {
            return Text(
              state.selectedConversation?.title ?? '对话详情',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.go('/chat?conversationId=${widget.conversationId}');
            },
            icon: const Icon(Icons.chat_outlined, size: 16),
            label: const Text('继续对话'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: BlocBuilder<ChatHistoryBloc, ChatHistoryState>(
          builder: (context, state) {
            if (state.status == ChatHistoryStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.error != null) {
              return Center(
                child: Text(
                  state.error!,
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 14),
                ),
              );
            }

            final detail = state.selectedConversation;
            if (detail == null) {
              return const SizedBox.shrink();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: detail.messages.length,
              itemBuilder: (context, index) {
                final msg = detail.messages[index];
                return _buildMessageBubble(msg);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg) {
    final isUser = msg.isUser;
    final timeStr =
        DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUser) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                timeStr,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
          ] else ...[
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
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.userBubbleBg : AppColors.aiBubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: AppColors.aiBubbleBorder),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color:
                      isUser ? AppColors.userBubbleText : AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!isUser) ...[
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                timeStr,
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
