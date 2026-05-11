import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/core/constants/app_strings.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_state.dart';
import 'package:health_xiaohe/presentation/blocs/chat/chat_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/chat/chat_event.dart';
import 'package:health_xiaohe/presentation/blocs/chat/chat_state.dart';
import 'package:health_xiaohe/presentation/router/app_router.dart';
import 'package:health_xiaohe/presentation/widgets/chat/chat_input_field.dart';
import 'package:health_xiaohe/presentation/widgets/chat/message_bubble.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  void _initChat() {
    if (!mounted) return;
    final routerState = GoRouterState.of(context);
    final convId = routerState.uri.queryParameters['conversationId'];
    if (convId != null && convId.isNotEmpty) {
      context.read<ChatBloc>().add(ChatLoadConversation(convId));
    } else {
      context.read<ChatBloc>().add(ChatInitialize());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSideDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  AppStrings.chatHomeTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.conversationId != null) {
                return IconButton(
                  icon: const Icon(Icons.add_comment, color: AppColors.primary),
                  tooltip: '新建对话',
                  onPressed: () {
                    context.read<ChatBloc>().add(ChatNewConversation());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: AppColors.danger,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
                if (state.messages.isNotEmpty) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length + 1, // +1 for welcome card
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildWelcomeCard();
                    }
                    return MessageBubble(message: state.messages[index - 1]);
                  },
                );
              },
            ),
          ),
          // 追问建议
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.suggestions.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8, runSpacing: 8,
                    children: state.suggestions.map((s) => GestureDetector(
                      onTap: () {
                        context.read<ChatBloc>().add(ChatSendMessage(s));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.aiBubbleBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.primaryDark)),
                      ),
                    )).toList(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Loading indicator
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        AppStrings.thinking,
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Input field
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return ChatInputField(
                onSendMessage: (message) {
                  context.read<ChatBloc>().add(ChatSendMessage(message));
                },
                onSendImage: (bytes) {
                  context.read<ChatBloc>().add(ChatSendMessage('', imageBytes: bytes));
                },
                onVoicePressed: () {
                  if (authState is AuthAuthenticated) {
                    _startVoiceCall();
                  }
                },
                onHealthRecordPressed: () {
                  context.push(AppRouter.healthRecords);
                },
                onCallPressed: () {
                  if (authState is AuthAuthenticated) {
                    _startVoiceCall();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _startVoiceCall() {
    final state = context.read<ChatBloc>().state;
    final convId = state.conversationId;
    if (convId != null) {
      context.go('/call?conversationId=$convId');
    } else {
      context.go(AppRouter.call);
    }
  }

  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userName = authState is AuthAuthenticated ? authState.user.nickname : '用户';
          final userPhone = authState is AuthAuthenticated ? authState.user.phone : '';

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 30,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (userPhone.isNotEmpty)
                      Text(
                        userPhone.replaceRange(3, 7, '****'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'AI 健康咨询',
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRouter.chatHome);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.favorite_outline,
                      title: '健康记录',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRouter.healthRecords);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.history,
                      title: '咨询历史',
                      color: AppColors.primaryDark,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRouter.chatHistory);
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_outline,
                      title: '个人中心',
                      color: AppColors.textTertiary,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(AppRouter.personalCenter);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '你好！我是健康小荷',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '您的专属 AI 健康管家',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '我可以帮你：解答健康问题、分析症状、提供养生建议。如有严重不适，请及时就医哦！',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick tips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickTip('失眠怎么办'),
              _buildQuickTip('血压正常值'),
              _buildQuickTip('春季养生'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTip(String text) {
    return GestureDetector(
      onTap: () {
        context.read<ChatBloc>().add(ChatSendMessage(text));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}
