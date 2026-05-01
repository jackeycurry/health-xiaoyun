import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_xiaohe/domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_authRepository.isLoggedIn) {
      final result = await _authRepository.getCurrentUser();
      if (result.success) {
        emit(AuthAuthenticated(result.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.login(event.phone, event.password);
    if (result.success) {
      emit(AuthAuthenticated(result.user!));
    } else {
      emit(AuthError(result.error ?? '登录失败'));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _authRepository.register(
      event.phone,
      event.password,
      nickname: event.nickname,
    );
    if (result.success) {
      emit(AuthRegistered(result.user!));
    } else {
      emit(AuthError(result.error ?? '注册失败'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
