import 'package:flutter/material.dart';
import '../services/health_rating_service.dart';
import '../data/product_ingredient_data.dart';
import '../services/open_food_api_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  int? _healthScore;
  List<String> _matchedIngredients = [];
  List<String> _harmfulIngredients = [];
  List<String> _searchHistory = []; // ✅ Track user searches

  List<String> _suggestions = [
    "coca cola", "fruit punch juice drink", "orange juice", "green tea",
    "peanut butter", "energy drink", "soda", "water", "protein bar", "chocolate milk",
    "almond milk", "yogurt", "granola bar", "cola zero", "monster energy",
    "apple juice", "lemonade", "snack chips", "diet soda", "sports drink",
    "sparkling water", "vegetable juice", "milk chocolate", "dark chocolate", "trail mix",
    "instant noodles", "smoothie drink", "coconut water", "kombucha", "soy milk",
    "cashew milk", "oat milk", "turmeric latte", "boba tea", "black tea", "herbal tea",
    "iced coffee", "protein shake", "mango juice", "pineapple juice", "carrot juice",
    "ginger ale", "red bull", "gatorade", "vitamin water", "cold brew coffee",
    "matcha latte", "chia pudding", "greek yogurt", "peach tea", "vegan protein bar",
    "protein cookies", "vegan chocolate", "cashew butter", "hazelnut spread",
    "cinnamon cereal", "organic apple juice", "plant-based protein bar",
    "kale chips", "rice cakes", "coconut yogurt", "whey protein powder",
    "pea protein drink", "ginger shots", "organic orange juice", "low sugar granola",
    "avocado smoothie", "spinach juice", "mixed berries", "pomegranate juice",
    "collagen water", "acai bowl", "oatmeal raisin cookie", "espresso shot",
    "green smoothie", "flavored sparkling water", "cherry juice", "kombucha tea",
    "high fiber cereal", "vegan cheese snack", "dark roast coffee", "low carb snack",
    "banana chips", "plant protein drink", "honey lemon tea", "beet juice",
    "recovery drink", "matcha powder", "ginger turmeric shot", "low fat milk",
    "cucumber water", "cashew yogurt", "cranberry juice", "iced matcha",
    "peanut butter smoothie",
  ];

  List<String> _filteredSuggestions = [];

  Future<void> _analyzeSearch() async {
    final input = _searchController.text.toLowerCase().trim();
    if (input.isEmpty) return;

    final apiService = OpenFoodApiService();
    List<String> ingredients = await apiService.fetchIngredients(input);

    if (ingredients.isEmpty) {
      ingredients = input.split(",").map((e) => e.trim()).toList();
    }

    final result = HealthRatingService.analyzeIngredients(ingredients);

    setState(() {
      _healthScore = result["score"];
      _matchedIngredients = ingredients;
      _harmfulIngredients = result["harmful_ingredients"] ?? [];
      _searchHistory.add(input); //  Save search history
      _filteredSuggestions.clear(); // Clear suggestions after search
    });

    if (result["harmful_count"] > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ ${result["harmful_count"]} harmful ingredient(s) detected!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget buildHealthScoreBadge(int score) {
    Color badgeColor;
    if (score >= 8) {
      badgeColor = Colors.green;
    } else if (score >= 5) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Health Score: $score/10",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildIngredientList(List<String> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          "Ingredients:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        ...ingredients.map((e) {
          final isHarmful = _harmfulIngredients.contains(e.toLowerCase());
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              "• $e",
              style: TextStyle(
                color: isHarmful ? Colors.red : Colors.black,
                fontWeight: isHarmful ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _updateSuggestions(String input) {
    setState(() {
      if (input.isEmpty) {
        _filteredSuggestions = _suggestions.take(8).toList(); // Show trending suggestions
      } else {
        _filteredSuggestions = _suggestions
            .where((item) => item.toLowerCase().contains(input.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrilens'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'product or ingredient',
                            border: InputBorder.none,
                          ),
                          onChanged: _updateSuggestions,
                          onSubmitted: (value) => _analyzeSearch(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _analyzeSearch,
                      ),
                    ],
                  ),
                  if (_filteredSuggestions.isNotEmpty)
                    ..._filteredSuggestions.map((suggestion) => ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _searchController.text = suggestion;
                        _filteredSuggestions.clear();
                        _analyzeSearch();
                      },
                    )),
                  if (_filteredSuggestions.isEmpty && _searchHistory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text("Recent Searches:", style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._searchHistory.reversed.take(5).map((e) => ListTile(
                          title: Text(e),
                          onTap: () {
                            _searchController.text = e;
                            _analyzeSearch();
                          },
                        )),
                      ],
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_healthScore != null)
              Center(child: buildHealthScoreBadge(_healthScore!)),
            if (_matchedIngredients.isNotEmpty)
              buildIngredientList(_matchedIngredients),
            if (_healthScore != null && _healthScore! <= 4)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    "⚠️ Consider healthier alternatives!",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/glossary');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Full Glossary",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_ingredients');
                  },
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: ThemeColor.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Add Ingredients",
                    //style: TextStyle(color: ThemeColor.textPrimary, fontSize: 16),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search, color: Colors.green), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          if (index == 0) Navigator.pushNamed(context, '/settings');
          if (index == 1) Navigator.pushNamed(context, '/notifications');
          if (index == 2) Navigator.pushNamed(context, '/home');
          if (index == 3) Navigator.pushNamed(context, '/search');
          if (index == 4) Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }
}
