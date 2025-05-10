// health_rating_service.dart

class HealthRatingService {
  /// Ingredients and drinks flagged as unhealthy with weights (1 = most harmful)
  static final Map<String, int> harmfulItems = {
    "sodium nitrate": 2,
    "high fructose": 2,
    "syrup": 1,
    "partially hydrogenated": 1,
    "aspartame": 2,
    "msg": 2,
    "bht": 1,
    "artificial": 1,
    "sodium benzoate": 2,
    "potassium bromate": 1,
    "trans fat": 1,
    "propyl gallate": 2,
    "phosphoric acid": 2,
    "caffeine": 2,
    "coloring": 1,
    "soda": 1,
    "energy drink": 2,
    "alcohol": 1
  };

  /// Ingredients and drinks considered healthy with weights (10 = most beneficial)
  static final Map<String, int> healthyItems = {
    "fiber": 9,
    "vitamin c": 10,
    "calcium": 8,
    "iron": 7,
    "protein": 9,
    "whole grain": 9,
    "omega-3": 10,
    "antioxidants": 10,
    "water": 10,
    "green tea": 9,
    "herbal tea": 9,
    "coconut water": 8,
    "vegetable juice": 9
  };

  /// Analyze and return a health score from 1 to 10
  static Map<String, dynamic> analyzeIngredients(List<String> items) {
    int totalScore = 0;
    int count = 0;
    int harmfulCount = 0;
    int healthyCount = 0;

    for (String item in items) {
      final lower = item.toLowerCase();
      bool matched = false;

      for (var entry in harmfulItems.entries) {
        if (lower.contains(entry.key)) {
          totalScore += entry.value;
          count++;
          harmfulCount++;
          matched = true;
          break;
        }
      }

      if (!matched) {
        for (var entry in healthyItems.entries) {
          if (lower.contains(entry.key)) {
            totalScore += entry.value;
            count++;
            healthyCount++;
            break;
          }
        }
      }
    }

    double average = count == 0 ? 5.0 : totalScore / count;
    int score = average.round().clamp(1, 10);

    return {
      "score": score,
      "harmful_count": harmfulCount,
      "healthy_count": healthyCount
    };
  }
}
