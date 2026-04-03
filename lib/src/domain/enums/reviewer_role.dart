enum ReviewerRole {
  client,
  provider;

  static ReviewerRole fromString(String value) {
    return ReviewerRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReviewerRole.client,
    );
  }
}
