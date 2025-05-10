import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:firebase_database/firebase_database.dart';

class AlbertsonsDealsScraper {
  final DatabaseReference _dealsRef = FirebaseDatabase.instance.ref('albertsons_deals');

  Future<void> scrapeAndSaveDeals() async {
    final url = 'https://local.albertsons.com/ca/los-angeles/600-north-western-avenue/weekly-specials.html';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        final productElements = document.querySelectorAll('div.product-details');

        for (var item in productElements) {
          final title = item.querySelector('.product-title')?.text.trim() ?? 'No Title';
          final price = item.querySelector('.product-price')?.text.trim() ?? 'Price Not Listed';

          print('🛒 Item: $title | 💵 Price: $price');

          await _dealsRef.push().set({
            'title': title,
            'price': price,
            'source': 'Albertsons',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        print('❌ Failed to load Albertsons deals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error scraping Albertsons: $e');
    }
  }
}
