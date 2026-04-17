import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.get('SUPABASE_URL');
    final anonKey = dotenv.get('SUPABASE_ANON_KEY');

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<StudentProfile?> fetchCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return StudentProfile.fromJson(response);
  }

  static Future<void> loadCurrentProfileToAppState() async {
    try {
      final profile = await fetchCurrentProfile();
      if (profile != null) {
        MockData.setStudent(profile);
      }
    } catch (_) {
      MockData.resetStudent();
    }
  }

  static void resetAppProfile() {
    MockData.resetStudent();
  }
}
