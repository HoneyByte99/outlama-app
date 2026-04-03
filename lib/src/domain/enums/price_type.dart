enum PriceType {
  hourly,
  fixed;

  static PriceType fromString(String value) {
    return PriceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PriceType.fixed,
    );
  }
}
