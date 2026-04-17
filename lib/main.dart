import 'package:flutter/material.dart';
import 'core/supabase/supabase_service.dart';
import 'features/shell/app_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SupabaseService.initialize();
  
  runApp(const KampusApp());
}
