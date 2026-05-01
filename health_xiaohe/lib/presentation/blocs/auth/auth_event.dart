import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const AuthLoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String phone;
  final String password;
  final String? nickname;

  const AuthRegisterRequested({
    required this.phone,
    required this.password,
    this.nickname,
  });

  @override
  List<Object?> get props => [phone, password, nickname];
}

class AuthLogoutRequested extends AuthEvent {}
