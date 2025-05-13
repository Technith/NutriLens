// search_page.dart (scrollable suggestions + glossary and add buttons)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  List<String> _suggestions = [];
  List<String> _filteredSuggestions = [];
  bool _isLoading = false;
  List<String> _ingredients = [];
  List<String> _harmfulIngredients = [];
  int? _score;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('searchable_products/products')
        .get();
    if (snapshot.exists) {
      final keys = snapshot.children.map((e) => e.key ?? '').toList();
      final readable = keys.map((k) => k.replaceAll('_', ' ')).toList();
      setState(() {
        _suggestions = readable;
        _filteredSuggestions = readable;
      });
    }
  }

  void _searchProduct([String? overrideInput]) async {
    final query = overrideInput ?? _controller.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _filteredSuggestions.clear();
    });

    final slug = query.replaceAll(' ', '_');
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('searchable_products/products/$slug')
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        _ingredients = List<String>.from(data['ingredients'] ?? []);
        _harmfulIngredients = List<String>.from(data['harmfulIngredients'] ?? []);
        _score = data['healthScore'];
        _isLoading = false;
      });

      if (_harmfulIngredients.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ ${_harmfulIngredients.length} harmful ingredient(s) found."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        _ingredients = [];
        _harmfulIngredients = [];
        _score = null;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Product not found in database."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _updateSuggestions(String input) {
    final query = input.toLowerCase();
    setState(() {
      _filteredSuggestions = _suggestions
          .where((s) => s.toLowerCase().contains(query))
          .toList();
    });
  }

  Widget _buildScoreBadge() {
    if (_score == null) return const SizedBox.shrink();
    Color color = _score! >= 8 ? Colors.green : _score! >= 5 ? Colors.orange : Colors.red;
    return Chip(
      label: Text('Health Score: $_score/10', style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildIngredientList() {
    if (_ingredients.isEmpty) return const Text('No ingredients found.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _ingredients.map((e) => Text(
        '• $e',
        style: TextStyle(
          color: _harmfulIngredients.contains(e) ? Colors.red : Colors.black,
          fontWeight: _harmfulIngredients.contains(e) ? FontWeight.bold : FontWeight.normal,
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NutriLens Search')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search for a product...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchProduct,
                ),
              ),
              onChanged: _updateSuggestions,
              onSubmitted: (_) => _searchProduct(),
            ),
            const SizedBox(height: 10),
            if (_filteredSuggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _controller.text = suggestion;
                        _searchProduct(suggestion);
                      },
                    );
                  },
                ),
              ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (!_isLoading && _score != null) ...[
              _buildScoreBadge(),
              const SizedBox(height: 10),
              _buildIngredientList(),
            ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "Add Ingredients",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}