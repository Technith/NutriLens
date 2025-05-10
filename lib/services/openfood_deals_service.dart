import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodDealsService {
  Future<List<Map<String, String>>> fetchGroceryDeals({String category = 'snacks'}) async {
    final url = 'https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=categories&tag_contains_0=contains&tag_0=$category&json=1&page_size=20';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'];

        if (products != null && products is List) {
          return products.map<Map<String, String>>((product) {
            return {
              'title': product['product_name'] ?? 'Unknown Product',
              'brand': product['brands'] ?? 'Unknown Brand',
              'categories': (product['categories_tags'] as List<dynamic>?)?.join(', ') ?? 'Unknown Category',
              'image_url': product['image_front_small_url'] ?? '',
              'store': product['stores_tags'] != null && product['stores_tags'].isNotEmpty
                  ? (product['stores_tags'] as List<dynamic>).join(', ')
                  : 'Various stores',
              'discount': (5 + (product['nutriscore_score'] ?? 0) % 30).toString(), // Dummy discount
            };
          }).toList();
        }
      } else {
        print('Failed to fetch OpenFoodFacts products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching OpenFoodFacts products: $e');
    }

    return [];
  }
}
