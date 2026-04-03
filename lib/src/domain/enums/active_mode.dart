enum ActiveMode {
  client,
  provider;

  static ActiveMode fromString(String value) {
    return ActiveMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ActiveMode.client,
    );
  }
}
