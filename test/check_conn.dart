import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- Supabase Bağlantı Testi ---');
  
  final envFile = File('.env');
  if (!await envFile.exists()) {
    print('Hata: .env dosyası bulunamadı!');
    return;
  }

  final lines = await envFile.readAsLines();
  String? url;
  String? key;

  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
        url = line.split('=')[1].trim();
    }
    if (line.startsWith('SUPABASE_ANON_KEY=')) {
        key = line.split('=')[1].trim();
    }
  }

  if (url == null || key == null) {
    print('Hata: .env dosyasında URL veya KEY eksik!');
    return;
  }

  print('URL: $url');
  print('Anahtar kontrol ediliyor...');

  try {
    final client = HttpClient();
    // Supabase REST API endpoint (health check info)
    final request = await client.getUrl(Uri.parse('$url/rest/v1/'));
    request.headers.add('apikey', key);
    
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('Başarılı! Supabase projesine ulaşıldı (Kod 200).');
    } else {
      print('Bağlantı Denendi, Durum Kodu: ${response.statusCode}');
      final body = await response.transform(utf8.decoder).join();
      print('Sunucu Yanıtı: $body');
    }
  } catch (e) {
    print('Hata: Bağlantı sırasında bir problem oluştu: $e');
  }
}
