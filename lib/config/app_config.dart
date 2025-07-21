class AppConfig {
  // TODO: Replace with your actual Vercel deployment URL
  static const String backendUrl = 'https://eirabackend-2j3uqcu6x-mohammadoweisis23-6585s-projects.vercel.app';
  
  // Debug settings
  static const bool enableDebugLogs = true;
  static const bool enableMockMode = false; // Set to true for offline testing
  
  static bool get isBackendConfigured => !backendUrl.contains('your-vercel-app');
  
  static void printDebug(String message) {
    if (enableDebugLogs) {
      print('🐛 [DEBUG] $message');
    }
  }
  
  static void printError(String message) {
    print('❌ [ERROR] $message');
  }
  
  static void printSuccess(String message) {
    print('✅ [SUCCESS] $message');
  }
}
