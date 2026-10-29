class SupabaseConfig {
  static const String url = 'https://pqeicvohoegcczvdxtiz.supabase.co';
  static const String anonKey = 'sb_publishable_sdWzGfzQTTBSKPRG0hX-Sg_gKosUM83';

  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      !url.contains('YOUR_SUPABASE_URL');
}
