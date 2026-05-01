import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/core/theme/app_theme.dart';
import 'package:health_xiaohe/injection.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_event.dart';
import 'package:health_xiaohe/presentation/blocs/chat/chat_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/health/health_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_bloc.dart';
import 'package:health_xiaohe/presentation/router/app_router.dart';

class HealthXiaoheApp extends StatelessWidget {
  const HealthXiaoheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<ChatBloc>(
          create: (_) => getIt<ChatBloc>(),
        ),
        BlocProvider<HealthBloc>(
          create: (_) => getIt<HealthBloc>(),
        ),
        BlocProvider<VoiceBloc>(
          create: (_) => getIt<VoiceBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: '健康小荷',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
