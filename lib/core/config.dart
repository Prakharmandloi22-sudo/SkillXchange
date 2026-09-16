// IMPORTANT: Never commit real API keys to source control.
// Set these values via --dart-define at build time:
//   flutter run --dart-define=OPEN_ROUTER_KEY=your_key --dart-define=AGORA_APP_ID=your_id
class AppConfig {
  static const String openRouterKey =
      String.fromEnvironment('OPEN_ROUTER_KEY', defaultValue: '');

  static const String agoraAppId =
      String.fromEnvironment('AGORA_APP_ID', defaultValue: '');

  // ── Cloudinary Config ──────────────────────────────────
  static const String cloudinaryCloudName = 
      String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'dhngu51ri');
  
  static const String cloudinaryUploadPreset = 
      String.fromEnvironment('CLOUDINARY_PRESET', defaultValue: 'ml_default');
}
