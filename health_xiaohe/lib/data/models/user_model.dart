class UserModel {
  final String id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String? ?? '健康用户',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TokenModel {
  final String accessToken;
  final String tokenType;

  TokenModel({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}
