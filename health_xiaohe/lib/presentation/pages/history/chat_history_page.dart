import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_event.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_state.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatHistoryBloc>().add(ChatHistoryLoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '咨询历史',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
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
            if (state.status == ChatHistoryStatus.loading &&
                state.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == ChatHistoryStatus.error &&
                state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.error_outline,
                            color: AppColors.danger, size: 40),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.error ?? '加载失败',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ChatHistoryBloc>()
                          .add(ChatHistoryLoadConversations()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('重试',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Text('💬', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '暂无咨询历史',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '与健康小云的对话将显示在这里',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ChatHistoryBloc>()
                    .add(ChatHistoryLoadConversations());
                // Wait for the state to update
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.conversations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final conv = state.conversations[index];
                  return _buildConversationCard(conv);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _regenerateTitle(String conversationId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在重新生成标题…'), duration: Duration(seconds: 2)),
    );
    try {
      final api = GetIt.instance<ApiClient>();
      await api.dio.post('/api/consult/conversations/$conversationId/regenerate-title');
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('标题已更新'), backgroundColor: AppColors.success),
      );
      // ignore: use_build_context_synchronously
      context.read<ChatHistoryBloc>().add(ChatHistoryLoadConversations());
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('生成失败：$e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Widget _buildConversationCard(dynamic conv) {
    final dateStr = DateFormat('MM/dd HH:mm').format(conv.createdAt);
    final id = conv.id as String;

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('删除后无法恢复，确定要删除这个对话吗？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) {
        context.read<ChatHistoryBloc>().add(ChatHistoryDeleteConversation(id));
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 20))),
          ),
          title: Text(
            conv.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '继续对话',
                icon: const Icon(Icons.chat_outlined, size: 18, color: AppColors.primary),
                onPressed: () => context.go('/chat?conversationId=$id'),
              ),
              PopupMenuButton<String>(
                tooltip: '更多',
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textTertiary),
                onSelected: (action) {
                  if (action == 'regenerate') {
                    _regenerateTitle(id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'regenerate',
                    child: Row(children: [
                      Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('重新生成标题'),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => context.push('/chat-history/$id'),
        ),
      ),
    );
  }
}
