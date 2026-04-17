import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
