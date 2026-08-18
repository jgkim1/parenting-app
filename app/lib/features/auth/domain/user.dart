class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.role,
  });

  final String id;
  final String email;
  final String nickname;
  final String role;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        nickname: json['nickname'] as String,
        role: json['role'] as String,
      );
}
