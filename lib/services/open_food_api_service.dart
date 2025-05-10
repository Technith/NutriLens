import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodApiService {
  /// Fetch and clean ingredient list for a given product from OpenFoodFacts
  Future<List<String>> fetchIngredients(String productName) async {
    final url =
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$productName&search_simple=1&action=process&json=1';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'];
        if (products != null && products.isNotEmpty) {
          final product = products[0];

          // Try structured ingredients first
          final ingredientsList = product['ingredients'];
          if (ingredientsList != null && ingredientsList is List) {
            final structured = ingredientsList
                .map<String>((item) => item['text']?.toString() ?? '')
                .where((line) => line.isNotEmpty)
                .toList();
            if (structured.isNotEmpty) return structured;
          }

          // Fallback to ingredients_text
          final raw = product['ingredients_text'] ?? '';
          final cleaned = raw
              .split(RegExp(r'[•\n\r]+'))
              .map((e) => e.trim())
              .where((line) =>
          line.isNotEmpty &&
              RegExp(r'[a-zA-Z]').hasMatch(line) &&
              !line.contains(RegExp(r'\b(fr|nl|de|et|es|pt)\b')))
              .toSet()
              .toList();

          return cleaned;
        }
      }
    } catch (e) {
      print('❌ Error fetching from OpenFoodFacts: $e');
    }
    return [];
  }
}