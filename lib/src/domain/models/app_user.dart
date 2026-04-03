import '../enums/active_mode.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.country,
    required this.activeMode,
    required this.createdAt,
    this.photoPath,
    this.phoneE164,
    this.pushToken,
  });

  final String id;
  final String displayName;
  final String email;
  final String? photoPath;
  final String? phoneE164;
  final String country;
  final ActiveMode activeMode;
  final String? pushToken;
  final DateTime createdAt;

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoPath,
    String? phoneE164,
    String? country,
    ActiveMode? activeMode,
    String? pushToken,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      phoneE164: phoneE164 ?? this.phoneE164,
      country: country ?? this.country,
      activeMode: activeMode ?? this.activeMode,
      pushToken: pushToken ?? this.pushToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
