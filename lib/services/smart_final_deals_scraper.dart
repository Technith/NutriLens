import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:firebase_database/firebase_database.dart';

class SmartFinalDealsScraper {
  final DatabaseReference _dealsRef = FirebaseDatabase.instance.ref('smart_final_deals');

  Future<void> scrapeAndSaveDeals() async {
    final url = 'https://smartandfinalweeklyad.com/';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        // Scrape product titles and prices
        final productTitles = document.querySelectorAll('div.item-title');
        final productPrices = document.querySelectorAll('div.item-price');

        for (int i = 0; i < productTitles.length; i++) {
          final title = productTitles[i].text.trim();
          final price = i < productPrices.length ? productPrices[i].text.trim() : 'Price not listed';

          print('🛒 Item: $title | 💵 Price: $price');

          // Save into Firebase
          await _dealsRef.push().set({
            'title': title,
            'price': price,
            'source': 'Smart & Final',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        print('❌ Failed to load Smart & Final deals: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error scraping Smart & Final: $e');
    }
  }
}
