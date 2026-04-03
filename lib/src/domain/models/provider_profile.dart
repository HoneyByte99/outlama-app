class ProviderProfile {
  const ProviderProfile({
    required this.uid,
    required this.active,
    required this.suspended,
    required this.createdAt,
    this.bio,
    this.serviceArea,
  });

  final String uid;
  final String? bio;
  final String? serviceArea;
  final bool active;
  final bool suspended;
  final DateTime createdAt;

  ProviderProfile copyWith({
    String? bio,
    String? serviceArea,
    bool? active,
    bool? suspended,
    DateTime? createdAt,
  }) {
    return ProviderProfile(
      uid: uid,
      bio: bio ?? this.bio,
      serviceArea: serviceArea ?? this.serviceArea,
      active: active ?? this.active,
      suspended: suspended ?? this.suspended,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
