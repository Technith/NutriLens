import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:firebase_database/firebase_database.dart';

class SproutsDealsScraper {
  final DatabaseReference _dealsRef = FirebaseDatabase.instance.ref('sprouts_deals');

  Future<void> scrapeAndSaveDeals() async {
    final url = 'https://www.sprouts.com/savings/weekly-ad/';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // Scrape product titles and prices
        final productElements = document.querySelectorAll('.weekly-ad-item');

        for (var item in productElements) {
          final title = item.querySelector('.weekly-ad-item-title')?.text.trim() ?? 'No Title';
          final price = item.querySelector('.weekly-ad-item-price')?.text.trim() ?? 'Price Not Listed';

          print('🛒 Item: $title | 💵 Price: $price');

          // Save into Firebase
          await _dealsRef.push().set({
            'title': title,
            'price': price,
            'source': 'Sprouts',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        print('❌ Failed to load Sprouts deals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error scraping Sprouts: $e');
    }
  }

}
