class ApiConstants {
  ApiConstants._();

  static const String pocketBaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'https://pocketbase.valgrindr.net',
  );

  static const String secureStorageAuthKey = 'pb_auth';
}
