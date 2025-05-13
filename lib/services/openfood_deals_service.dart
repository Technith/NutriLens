import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class OpenFoodDealsService {
  final DatabaseReference _firebaseRef = FirebaseDatabase.instance.ref("deals_cache");

  /// Load cached deals from Firebase first
  Future<List<Map<String, String>>> loadCachedDeals(String category) async {
    try {
      final snapshot = await _firebaseRef.child(category).once();
      if (snapshot.snapshot.value != null && snapshot.snapshot.value is List) {
        final data = List<Map<String, dynamic>>.from(snapshot.snapshot.value as List);
        return data.map<Map<String, String>>((deal) => deal.map((k, v) => MapEntry(k, v.toString()))).toList();
      }
    } catch (e) {
      print('Error loading cached deals: $e');
    }
    return [];
  }

  /// Fetch fresh grocery deals and update Firebase
  Future<List<Map<String, String>>> fetchGroceryDeals({String category = 'snacks'}) async {
    // Load cached deals immediately for faster UI
    final cachedDeals = await loadCachedDeals(category);

    // Fetch fresh data in the background
    final url =
        'https://world.openfoodfacts.org/cgi/search.pl?action=process&tagtype_0=categories&tag_contains_0=contains&tag_0=$category&json=1&page_size=20';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'];

        if (products != null && products is List) {
          final deals = products.map<Map<String, String>>((product) {
            return {
              'title': product['product_name'] ?? 'Unknown Product',
              'brand': product['brands'] ?? 'Unknown Brand',
              'categories': (product['categories_tags'] as List<dynamic>?)?.join(', ') ?? 'Unknown Category',
              'image_url': product['image_front_small_url'] ?? '',
              'store': product['stores_tags'] != null && product['stores_tags'].isNotEmpty
                  ? (product['stores_tags'] as List<dynamic>).join(', ')
                  : 'Various stores',
              'discount': (5 + (product['nutriscore_score'] ?? 0) % 30).toString(),
            };
          }).toList();

          // Cache fresh results to Firebase
          await _firebaseRef.child(category).set(deals);
          return deals;
        }
      } else {
        print('Failed to fetch OpenFoodFacts products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching OpenFoodFacts products: $e');
    }

    // Fallback to cached data if fetch fails
    return cachedDeals;
  }
}
