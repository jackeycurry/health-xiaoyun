import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_xiaohe/core/constants/app_colors.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_event.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_state.dart';
import 'package:health_xiaohe/presentation/router/app_router.dart';

class PersonalCenterPage extends StatelessWidget {
  const PersonalCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go(AppRouter.login);
          }
        },
        child: Column(
          children: [
            // User header with gradient background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthAuthenticated) {
                        return _buildUserHeader(state);
                      }
                      return const SizedBox(height: 120);
                    },
                  ),
                ),
              ),
            ),
            // Menu content
            Expanded(
              child: Container(
                color: AppColors.backgroundEnd,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // AI 画像入口
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.psychology_outlined,
                        iconColor: AppColors.primaryDark,
                        iconBg: AppColors.primaryLight,
                        title: 'AI 印象',
                        subtitle: '查看和管理 AI 对你的认识',
                        onTap: () => context.go(AppRouter.aiImpression),
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Settings card
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        iconColor: AppColors.secondary,
                        iconBg: const Color(0xFFF0F5FF),
                        title: '设置',
                        onTap: () {},
                      ),
                      _buildMenuItem(
                        icon: Icons.security_outlined,
                        iconColor: AppColors.warning,
                        iconBg: const Color(0xFFFFF7E6),
                        title: '账号安全',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // About card
                    _buildMenuCard([
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        iconColor: AppColors.success,
                        iconBg: const Color(0xFFF6FFED),
                        title: '关于我们',
                        onTap: () => _showAboutDialog(context),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        iconColor: AppColors.danger,
                        iconBg: const Color(0xFFFFF1F0),
                        title: '帮助与反馈',
                        onTap: () {},
                        showDivider: false,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _confirmLogout(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '退出登录',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(AuthAuthenticated state) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🌿', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.user.nickname,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.user.phone.replaceRange(3, 7, '****'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 70),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('🌿', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text('健康小云'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本: 1.0.0'),
            SizedBox(height: 12),
            Text(
              '健康小云是一款 AI 健康助手应用，'
              '为您提供专业的健康咨询服务。',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text(
              '退出',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
