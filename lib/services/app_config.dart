class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri apiUri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    if (apiBaseUrl.trim().isNotEmpty) {
      return Uri.parse(apiBaseUrl).resolve(normalizedPath);
    }
    return Uri.base.resolve(normalizedPath);
  }
}
