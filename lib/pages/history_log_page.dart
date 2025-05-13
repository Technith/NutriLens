import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryLogPage extends StatefulWidget {
  const HistoryLogPage({super.key});

  @override
  State<HistoryLogPage> createState() => _HistoryLogPageState();
}

class _HistoryLogPageState extends State<HistoryLogPage> {
  Map<String, dynamic> _historyData = {};
  Set<String> _userAllergenPreferences = {};
  int? _expandedIndex;
  String _searchQuery = '';
  String _dateFilter = 'all';

  final Map<String, List<String>> _allergenKeywordMap = { //for highlighting history log tiles
    "peanut": [
      "peanut", "peanuts", "roasted peanuts", "groundnut", "arachis", "peanut butter",
      "peanut flour", "peanut oil", "crushed peanuts"
    ],
    "tree nut": [
      "tree nut", "almond", "walnut", "cashew", "pecan", "hazelnut", "macadamia",
      "pine nut", "brazil nut", "nut paste", "nut butter", "nut oil", "mixed nuts"
    ],
    "milk": [
      "milk", "whole milk", "skim milk", "cream", "buttermilk", "cheese", "curd",
      "casein", "caseinate", "whey", "lactose", "dairy", "yogurt", "milk solids", "milk protein"
    ],
    "wheat": [
      "wheat", "whole wheat", "semolina", "durum", "spelt", "farro", "bulgur",
      "einkorn", "couscous", "graham flour", "wheat flour", "wheat starch"
    ],
    "gluten": [
      "gluten", "barley", "rye", "malt", "triticale", "brewer's yeast",
      "malted barley", "hydrolyzed wheat protein", "malt extract", "seitan"
    ],
    "shrimp": [
      "shrimp", "prawn", "prawns", "crustacean", "shell-on shrimp", "shrimp powder",
      "shrimp extract"
    ],
    "shellfish": [
      "shellfish", "crab", "lobster", "scallop", "clam", "mussel", "oyster",
      "crustaceans", "shellfish extract", "shellfish powder"
    ],
    "hazelnut": [
      "hazelnut", "hazelnuts", "filbert", "filberts", "hazelnut flour", "hazelnut oil"
    ],
    "oats": [
      "oat", "oats", "oatmeal", "rolled oats", "steel-cut oats", "instant oats", "oat bran", "oat flour"
    ],
    "legumes": [
      "legume", "legumes", "lentil", "lentils", "soy", "soybean", "soybeans",
      "green pea", "split pea", "mung bean", "mung beans", "black-eyed pea", "pigeon pea", "broad beans"
    ],
    "chickpeas": [
      "chickpea", "chickpeas", "garbanzo", "garbanzo bean", "garbanzo flour", "chana", "gram flour"
    ],
    "mustard": [
      "mustard", "mustard seed", "mustard flour", "yellow mustard", "brown mustard",
      "mustard oil", "dijon", "mustard extract", "mustard greens"
    ],
    "sunflower seeds": [
      "sunflower seed", "sunflower seeds", "sunflower kernel", "sunflower oil", "sunflower lecithin"
    ],
    "banana": [
      "banana", "bananas", "plantain", "plantains", "banana flour", "dried banana", "banana puree"
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserAllergenPreferences().then((_) => _loadHistory());
  }

  Future<void> _loadUserAllergenPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userAllergenPreferences = data.keys.map((e) => e.toLowerCase().trim()).toSet();
      });
    }
  }

  void _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _historyData = {};
      });
      return;
    }

    final uid = user.uid;
    final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('HistoryLog/$uid');

    final event = await _historyRef.once();

    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _historyData = data;
      });
    }
  }

  void _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    await FirebaseDatabase.instance.ref('HistoryLog/$uid').remove();

    setState(() {
      _historyData = {};
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ History log cleared.")),
    );
  }

  List<String> _filteredDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _historyData.entries.where((entry) {
      final dateTime = DateTime.tryParse(entry.key);
      if (dateTime == null) return false;

      if (_dateFilter == 'today') {
        return dateTime.isAfter(today);
      } else if (_dateFilter == 'week') {
        return dateTime.isAfter(startOfWeek);
      } else if (_dateFilter == 'month') {
        return dateTime.isAfter(startOfMonth);
      }
      return true;
    }).where((entry) {
      if (_searchQuery.isEmpty) return true;
      final product = entry.value['Product']?.toString().toLowerCase() ?? '';
      final ingredients = entry.value['Ingredients']?.toString().toLowerCase() ?? '';
      return product.contains(_searchQuery.toLowerCase()) || ingredients.contains(_searchQuery.toLowerCase());
    }).map((entry) => entry.key).toList()
      ..sort((a, b) => b.compareTo(a));
  }

  bool _hasAllergenMatch(String ingredientText) {
    final lower = ingredientText.toLowerCase();
    for (final allergen in _userAllergenPreferences) {
      final keywords = _allergenKeywordMap[allergen] ?? [];
      for (final keyword in keywords) {
        if (lower.contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDates = _filteredDates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products or ingredients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("All"),
                  selected: _dateFilter == 'all',
                  onSelected: (_) => setState(() => _dateFilter = 'all'),
                ),
                FilterChip(
                  label: const Text("Today"),
                  selected: _dateFilter == 'today',
                  onSelected: (_) => setState(() => _dateFilter = 'today'),
                ),
                FilterChip(
                  label: const Text("This Week"),
                  selected: _dateFilter == 'week',
                  onSelected: (_) => setState(() => _dateFilter = 'week'),
                ),
                FilterChip(
                  label: const Text("This Month"),
                  selected: _dateFilter == 'month',
                  onSelected: (_) => setState(() => _dateFilter = 'month'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  onPressed: _clearHistory,
                  label: const Text("Clear History"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                )
              ],
            ),
          ),
          Expanded(
            child: _historyData.isEmpty
                ? const Center(child: Text("No history available."))
                : ListView.builder(
              itemCount: filteredDates.length,
              itemBuilder: (context, index) {
                final date = filteredDates[index];
                final entry = Map<String, dynamic>.from(_historyData[date]);
                final isExpanded = _expandedIndex == index;
                final ingredientText = entry['Ingredients']?.toString() ?? '';
                final hasAllergen = _hasAllergenMatch(ingredientText);

                return Stack(
                  children: [
                    Card(
                      color: hasAllergen ? Colors.red.shade100 : null,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
                        title: Row(
                          children: [
                            Expanded(child: Text(entry['Product'] ?? 'Unknown Product')),
                            if (hasAllergen)
                              const Tooltip(
                                message: "⚠️ Contains ingredients matching your allergen preferences",
                                child: Icon(Icons.info_outline, color: Colors.red, size: 18),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(date),
                            if (isExpanded) const SizedBox(height: 8),
                            if (isExpanded)
                              Text("Ingredients: ${entry['Ingredients'] ?? 'Unknown'}"),
                            if (isExpanded)
                              Text("Overall Health Score: ${entry['Overall Health Score'] ?? 'N/A'}"),
                          ],
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? null : index;
                          });
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 20,
                      child: GestureDetector(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final uid = user.uid;
                          await FirebaseDatabase.instance.ref('HistoryLog/$uid/$date').remove();

                          setState(() {
                            _historyData.remove(date);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ Deleted $date entry.")),
                          );
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
