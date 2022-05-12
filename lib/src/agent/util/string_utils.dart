class StringUtils {
  /// Checks if the provided [String] is null, empty or only
  /// full of whitespaces
  static bool isStringNullEmptyOrWhitespace(String? s) {
    return isStringNullOrEmpty(s) || s!.trim().isEmpty;
  }

  /// Checks if the provided [String] is null, empty
  static bool isStringNullOrEmpty(String? s) {
    return s == null || s.isEmpty;
  }
}
