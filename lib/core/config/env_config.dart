class EnvConfig {
  EnvConfig._();

  // Raw values from --dart-define-from-file=.env
  static const String _supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String _fonnte =
      String.fromEnvironment('FONNTE_TOKEN', defaultValue: '');
  static const String _midtransClientKey =
      String.fromEnvironment('MIDTRANS_CLIENT_KEY', defaultValue: '');
  static const String _midtransProd =
      String.fromEnvironment('MIDTRANS_IS_PRODUCTION', defaultValue: 'false');

  // Trimmed getters — prevents whitespace/newline issues from .env file
  static String get supabaseUrl      => _supabaseUrl.trim();
  static String get supabaseAnonKey  => _supabaseAnonKey.trim();
  static String get geminiApiKey     => _geminiApiKey.trim();
  static String get geminiModel      =>
      const String.fromEnvironment('GEMINI_MODEL',
          defaultValue: 'gemini-2.5-flash').trim();
  static String get fonnte           => _fonnte.trim();
  static String get midtransClientKey => _midtransClientKey.trim();
  static bool   get midtransIsProduction => _midtransProd.trim() == 'true';
  static String get appEnv           =>
      const String.fromEnvironment('APP_ENV',
          defaultValue: 'development').trim();

  // Feature flags
  // Supabase: URL must start with https:// and key must start with eyJ (JWT)
  static bool get useSupabase =>
      supabaseUrl.startsWith('https://') &&
      supabaseAnonKey.startsWith('eyJ') &&
      supabaseAnonKey.length > 100;

  // Gemini: key must start with AIza
  static bool get useGemini  =>
      geminiApiKey.startsWith('AIza') && geminiApiKey.length > 20;

  static bool get useFonnte  => fonnte.isNotEmpty && fonnte.length > 5;
  static bool get useMidtrans => midtransClientKey.isNotEmpty;
  static bool get isDev       => appEnv == 'development';

}