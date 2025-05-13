import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';

class ApiService {
  /// Fetch latest FDA food recalls
  Future<void> fetchFDARecalls() async {
    final String url = "https://api.fda.gov/food/enforcement.json?limit=50&sort=report_date:desc";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List recalls = data["results"];

        for (var recall in recalls) {
          String product = recall['product_description'];
          String reason = recall['reason_for_recall'];
          String date = recall['recall_initiation_date'];

          print("🚨 Recall: $product | Reason: $reason | Date: $date");

          // Save to Firebase only if it's not a duplicate
          await saveRecallToFirebase(product, reason, date);
        }
      } else {
        print("⚠️ Failed to fetch recalls: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching FDA recalls: $e");
    }
  }

  /// Save recall alerts to Firebase (deduplicated)
  Future<void> saveRecallToFirebase(String product, String reason, String date) async {
    final String key = '${product.hashCode}_$date';
    final DatabaseReference ref = FirebaseDatabase.instance.ref("recalls/$key");

    final snapshot = await ref.get();
    if (!snapshot.exists) {
      await ref.set({
        "product": product,
        "reason": reason,
        "date": date,
      });
      print("✅ Recall saved to Firebase!");
    } else {
      print("⚠️ Duplicate recall skipped: $product ($date)");
    }
  }

  /// Fetch ingredient warnings from USDA database
  Future<void> fetchUSDAIngredientInfo(String ingredient) async {
    final String apiKey = "YOUR_API_KEY"; // Replace with your USDA API Key
    final String url = "https://api.nal.usda.gov/fdc/v1/foods/search?query=$ingredient&api_key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List foods = data["foods"];

        for (var food in foods) {
          String description = food['description'];
          print("📝 Ingredient: $description");

          // Save flagged ingredient alerts to Firebase
          await saveIngredientWarningToFirebase(ingredient, "Potential health risks found");
        }
      } else {
        print("⚠️ Failed to fetch ingredient info: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching ingredient info: $e");
    }
  }

  /// Save ingredient warnings to Firebase
  Future<void> saveIngredientWarningToFirebase(String ingredient, String risk) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("ingredient_alerts");

    await ref.child(ingredient.toLowerCase()).set({
      "risk": risk,
      "source": "FDA",
      "date": DateTime.now().toIso8601String(),
    });

    print("✅ Ingredient alert saved to Firebase!");
  }
}
