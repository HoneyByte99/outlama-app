enum CategoryId {
  menage,
  plomberie,
  jardinage,
  autre;

  static CategoryId fromString(String value) {
    return CategoryId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CategoryId.autre,
    );
  }
}
