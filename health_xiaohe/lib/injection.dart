import 'package:get_it/get_it.dart';
import 'package:health_xiaohe/core/network/api_client.dart';
import 'package:health_xiaohe/core/network/websocket_client.dart';
import 'package:health_xiaohe/core/storage/local_storage.dart';
import 'package:health_xiaohe/data/repositories/auth_repository_impl.dart';
import 'package:health_xiaohe/data/repositories/health_repository_impl.dart';
import 'package:health_xiaohe/data/repositories/chat_repository_impl.dart';
import 'package:health_xiaohe/domain/repositories/auth_repository.dart';
import 'package:health_xiaohe/domain/repositories/health_repository.dart';
import 'package:health_xiaohe/domain/repositories/chat_repository.dart';
import 'package:health_xiaohe/presentation/blocs/auth/auth_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/chat/chat_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/chat_history/chat_history_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/health/health_bloc.dart';
import 'package:health_xiaohe/presentation/blocs/voice/voice_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  final localStorage = LocalStorage();
  await localStorage.init();
  getIt.registerSingleton<LocalStorage>(localStorage);

  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerLazySingleton<WebSocketClient>(() => WebSocketClient());

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<ApiClient>(),
      getIt<LocalStorage>(),
    ),
  );
  getIt.registerLazySingleton<HealthRepository>(
    () => HealthRepositoryImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(getIt<ApiClient>()),
  );

  // BLoCs
  getIt.registerFactory<AuthBloc>(() => AuthBloc(getIt<AuthRepository>()));
  getIt.registerFactory<ChatBloc>(() => ChatBloc(getIt<ChatRepository>()));
  getIt.registerFactory<ChatHistoryBloc>(() => ChatHistoryBloc(getIt<ChatRepository>()));
  getIt.registerFactory<HealthBloc>(() => HealthBloc(getIt<HealthRepository>()));
  getIt.registerFactory<VoiceBloc>(() => VoiceBloc(getIt<WebSocketClient>()));
}
