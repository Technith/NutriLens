import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlossaryPage extends StatefulWidget {

  final String? defaultFilter;
  final bool resetOnOpen;

  const GlossaryPage({Key? key, this.defaultFilter, this.resetOnOpen = false}) : super(key: key);




  @override
  _GlossaryPageState createState() => _GlossaryPageState();
}

class _GlossaryPageState extends State<GlossaryPage> {
  List<String> _trendingIngredients = [];
  String _searchQuery = '';
  Set<String> _userAllergenPreferences = {}; // new for allergen color highlighting
  Set<String> _userDietaryPreferences = {};

  Future<void> _loadTrendingFromHistory() async {
    final ref = FirebaseDatabase.instance.ref("HistoryLog");
    final snapshot = await ref.get();
    if (!snapshot.exists) return;

    final Map<dynamic, dynamic> allUserNodes = Map.from(snapshot.value as Map);
    final Map<String, int> ingredientFrequency = {};

    for (var userNode in allUserNodes.values) {
      if (userNode is Map) {
        for (var scanEntry in userNode.values) {
          final rawIngredients = scanEntry["Ingredients"];
          if (rawIngredients != null && rawIngredients is String) {
            final ingredients = rawIngredients.split(",");
            for (var item in ingredients) {
              final cleaned = item.trim().toLowerCase();
              if (cleaned.isNotEmpty) {
                ingredientFrequency[cleaned] = (ingredientFrequency[cleaned] ?? 0) + 1;
              }
            }
          }
        }
      }
    }

    final sorted = ingredientFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    setState(() {
      _trendingIngredients = sorted.take(3).map((e) => e.key).toList();
    });
  }


  List<Widget> _buildSubstitutionWidgets(dynamic allergenMatchesRaw) {
    final matches = List<String>.from(allergenMatchesRaw ?? []);
    final suggestions = <Widget>[];

    for (final match in matches) {
      final lower = match.toLowerCase().trim();
      if (_userAllergenPreferences.contains(lower) && substitutionMap.containsKey(lower)) {
        suggestions.add(
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              "🔁 Suggested Substitution for $match: ${substitutionMap[lower]!.join(', ')}",
              style: const TextStyle(color: Colors.deepOrange),
            ),
          ),
        );
      }
    }

    return suggestions;
  }




  Future<void> _loadUserAllergenPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final allergenRef = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
    final snapshot = await allergenRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userAllergenPreferences = Set<String>.from(
            data.keys.map((e) => e.trim().toLowerCase())
        );
      });
    }
  }
  Future<void> _loadUserDietaryPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/DietaryPreferences");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userDietaryPreferences = Set<String>.from(data.keys.map((e) => e.toLowerCase()));
      });
    }
  }


  List<Map<String, dynamic>> _allIngredients = []; // Stores the full list of ingredients

  final DatabaseReference _ingredientsRef =
  FirebaseDatabase.instance.ref('Ingredients');

  List<Map<String, dynamic>> _displayedIngredients = [];
  Set<String> _userSafeIngredients = {}; // Tracks marked Safe
  Set<String> _userAvoidIngredients = {}; // Tracks marked Avoid
  int? _expandedIndex;
  bool _hasMore = true;

  final List<String> _availableAllergens = [
    "peanut", "tree nut", "milk", "wheat", "gluten", "shrimp",
    "shellfish", "hazelnut", "oats", "legumes", "chickpeas",
    "mustard", "sunflower seeds", "banana"
  ];
  final Map<String, List<String>> substitutionMap = {
    "milk": ["oat milk", "soy milk", "rice milk", "almond milk", "coconut milk"],
    "peanut": ["sunflower seed butter", "soy butter", "pumpkin seed butter", "pea butter"],
    "tree nut": ["pumpkin seeds", "sunflower seeds", "toasted oats", "roasted chickpeas"],
    "wheat": ["quinoa", "rice flour", "cornmeal", "buckwheat", "millet"],
    "gluten": ["rice", "sorghum", "amaranth", "teff", "corn flour"],
    "shrimp": ["jackfruit", "hearts of palm", "white beans (for texture)"],
    "shellfish": ["mushrooms", "eggplant", "tofu", "zucchini", "artichoke hearts"],
    "hazelnut": ["pumpkin seeds", "roasted chickpeas", "toasted oats"],
    "oats": ["quinoa flakes", "buckwheat groats", "amaranth", "rice flakes"],
    "legumes": ["quinoa", "millet", "buckwheat", "animal protein (if applicable)"],
    "chickpeas": ["cooked lentils", "white beans", "edamame (if not allergic to soy)"],
    "mustard": ["horseradish", "wasabi", "turmeric", "dijon-free dressings"],
    "sunflower seeds": ["pumpkin seeds", "hemp seeds", "chia seeds"],
    "banana": ["applesauce", "avocado", "mashed pear", "pumpkin puree"],
  };

/*
  final List<String> _availableCategories = [
    "Dairy", "Seafood", "Grain", "Fruit", "Spread", "Oil", "Spice"
  ]; */

  @override
  void initState() {
    super.initState();
    _loadTrendingFromHistory();

    _loadUserAllergenPreferences();
    _loadUserPreferences();
    _loadUserDietaryPreferences(); // <--- Add this
    _loadIngredients();
    _listenForUpdates();


    if (widget.resetOnOpen) {
      _userSafeIngredients.clear();
      _userAvoidIngredients.clear();
    }


    if (widget.defaultFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _filterIngredients(widget.defaultFilter!);
      });
    }
  }



  void _listenForUpdates() {
    _ingredientsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> data =
        event.snapshot.value as Map<dynamic, dynamic>;

        List<Map<String, dynamic>> updatedIngredients = [];

        data.forEach((key, value) {
          updatedIngredients.add({
            "name": value["IngredientName"]?.toString() ?? "Unknown",
            "description": value["Description"]?.toString() ?? "No description available.",
            "healthImpact": value["HealthImpact"]?.toString() ?? "No health impact info.",
            "warnings": value["Warnings"]?.toString() ?? "No warnings available.",
            "category": value["Category"]?.toString() ?? "No category provided.",
            "allergenRisk": value["AllergenRisk"] == true ? "Yes" : "No",
            "commonUses": value["CommonUses"] is List<dynamic>
                ? (value["CommonUses"] as List<dynamic>).map((e) => e.toString()).join(", ")
                : (value["CommonUses"]?.toString() ?? "No common uses listed."),
            "allergenMatch": value["AllergenMatch"] ?? [],
            "DietaryTags": value["DietaryTags"] ?? [],
          });
        });

        setState(() {
          _allIngredients = updatedIngredients;
          _displayedIngredients = updatedIngredients.where((ingredient) =>
              ingredient['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        });
      }
    });
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefsRef = FirebaseDatabase.instance
        .ref("Users/${user.uid}/IngredientPreferences");

    final snapshot = await prefsRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userSafeIngredients = Set<String>.from((data['safe'] ?? {}).keys);
        _userAvoidIngredients = Set<String>.from((data['avoid'] ?? {}).keys);
      });
    }
  }
  Future<void> _saveUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefsRef = FirebaseDatabase.instance
        .ref("Users/${user.uid}/IngredientPreferences");

    await prefsRef.set({
      "safe": {for (var item in _userSafeIngredients) item: true},
      "avoid": {for (var item in _userAvoidIngredients) item: true},
    });
  }






  Future<void> _loadIngredients() async {
    if (!_hasMore) return;

    DatabaseEvent event = await _ingredientsRef
        .orderByKey()
        .limitToFirst(_displayedIngredients.length + 10)
        .once();

    if (event.snapshot.exists) {
      setState(() {
        _hasMore = false; // Just load once
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Ingredients'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Show All'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('all');
                  },
                ),
                ListTile(
                  title: const Text('Only Allergen Risk'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('allergen');
                  },
                ),
                ListTile(
                  title: const Text('Only Safe'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('safe');
                  },
                ),
                ListTile(
                  title: const Text('Only Avoided'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('avoided');
                  },
                ),
                ListTile(
                  title: const Text('High Risk (Multiple Allergens)'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('highrisk');
                  },
                ),
                ListTile(
                  title: const Text('Low Risk (Single Allergen)'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('lowrisk');
                  },
                ),
                ListTile(
                  title: const Text('Sort Alphabetically'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterIngredients('alphabetical');
                  },
                ),
                ListTile(
                  title: const Text('Sort by Specific Allergen'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAllergenListDialog();
                  },
                ),
                /* ListTile(
                  title: const Text('Sort by Category'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCategoryListDialog();
                  },
                ), */
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllergenListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select an Allergen'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableAllergens.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_availableAllergens[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterBySpecificAllergen(_availableAllergens[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
/*
  void _showCategoryListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Category'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_availableCategories[index]),
                  onTap: () {
                    Navigator.of(context).pop();
                    _filterByCategory(_availableCategories[index]);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
*/
  void _filterBySpecificAllergen(String allergen) {
    setState(() {
      _displayedIngredients = _displayedIngredients.where((ingredient) {
        List<dynamic> matches = ingredient['allergenMatch'];
        return matches.contains(allergen);
      }).toList();
    });
  }
/*
  void _filterByCategory(String category) {
    setState(() {
      _displayedIngredients = _displayedIngredients.where((ingredient) {
        return ingredient['category'].toString().toLowerCase().contains(category.toLowerCase());
      }).toList();
    });
  }
  */
  void _filterIngredients(String filterType) {
    List<Map<String, dynamic>> filtered = [];

    if (filterType == 'all') {
      _listenForUpdates();
      return;
    }

    if (filterType == 'alphabetical') {
      List<Map<String, dynamic>> sortedList = List.from(_displayedIngredients);
      sortedList.sort((a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()));
      setState(() {
        _displayedIngredients = sortedList;
      });
      return;
    }

    for (var ingredient in _allIngredients) {
      final name = ingredient['name'];
      final matches = ingredient['allergenMatch'] ?? [];
      final ingredientAllergens = matches.map((e) => e.toString().toLowerCase().trim()).toList();

      if (filterType == 'allergen') {
        final userMatches = ingredientAllergens
            .where((a) => _userAllergenPreferences.contains(a))
            .toList();

        if (userMatches.isNotEmpty) {
          filtered.add(ingredient);
        }
      } else if (filterType == 'safe') {
        if ((ingredient['allergenRisk'] == 'No' || _userSafeIngredients.contains(name)) &&
            !_userAvoidIngredients.contains(name)) {
          filtered.add(ingredient);
        }
      } else if (filterType == 'avoided') {
        if (_userAvoidIngredients.contains(name)) {
          filtered.add(ingredient);
        }
      } else if (filterType == 'highrisk') {
        final matchCount = ingredientAllergens
            .where((a) => _userAllergenPreferences.contains(a))
            .length;

        if (matchCount > 1) {
          filtered.add(ingredient);
        }
      } else if (filterType == 'lowrisk') {
        final matchCount = ingredientAllergens
            .where((a) => _userAllergenPreferences.contains(a))
            .length;

        if (matchCount == 1) {
          filtered.add(ingredient);
        }
      }
    }

    setState(() {
      _displayedIngredients = filtered;
    });

  }

  Color _getTileColor(Map<String, dynamic> ingredient) {
    List<dynamic> matches = ingredient['allergenMatch'] ?? [];

    final Set<String> normalizedUserPrefs =
    _userAllergenPreferences.map((e) => e.toLowerCase().trim()).toSet();
    final List<String> ingredientAllergens = matches
        .map((e) => e.toString().toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Count how many user allergens match this ingredient
    final int userAllergenMatches = ingredientAllergens
        .where((a) => normalizedUserPrefs.contains(a))
        .length;

    if (userAllergenMatches > 1) {
      return Colors.red.shade200; // multiple user allergens
    } else if (userAllergenMatches == 1) {
      return Colors.red.shade100; // one user allergen
    }

    return Colors.white; // no match
  }








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'INGREDIENT GLOSSARY',
          style: TextStyle(fontSize: 18), // put style here
        ),

        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIngredients,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_trendingIngredients.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    "🔥 Trending Ingredients This Month",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_trendingIngredients.length, (index) {
                      final name = _trendingIngredients[index];
                      final medals = ["🥇", "🥈", "🥉"];
                      final medal = index < medals.length ? medals[index] : "#${index + 1}";

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 4),
                          Text(
                            name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          if (index < _trendingIngredients.length - 1)
                            const SizedBox(width: 16),
                        ],
                      );
                    }),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'quick search local ingredients...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.purple),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _displayedIngredients = _allIngredients.where((ingredient) =>
                            ingredient['name']
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase())).toList();
                      });
                    },
                  ),
                ),
              ],
            ),



          Expanded(
            child: ListView.builder(
              itemCount: _displayedIngredients.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _displayedIngredients.length && _hasMore) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ingredient = _displayedIngredients[index];
                final name = ingredient['name'];
                bool isExpanded = _expandedIndex == index;
                bool isSafeMarked = _userSafeIngredients.contains(name);
                bool isAvoidMarked = _userAvoidIngredients.contains(name);

                return Container(
                  color: _getTileColor(ingredient),
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(name),
                        if ((ingredient['DietaryTags'] ?? [])
                            .map((e) => e.toString().toLowerCase())
                            .any((tag) => _userDietaryPreferences.contains(tag)))
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: "Matches your dietary preferences",
                              child: Icon(Icons.thumb_up, color: Colors.green, size: 18),
                            ),
                          ),
                        if (isSafeMarked)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: "Your Safe Ingredient",
                              child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                            ),
                          ),
                        if (isAvoidMarked)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: "Your Avoided Ingredient",
                              child: Icon(Icons.block, color: Colors.red, size: 18),
                            ),
                          ),
                      ],
                    ),
                    subtitle: isExpanded
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Description: ${ingredient['description']}"),
                        Text("Health Impact: ${ingredient['healthImpact']}"),
                        Text("Warnings: ${ingredient['warnings']}"),
                        Text("Category: ${ingredient['category']}"),
                        Text("Allergen Risk: ${ingredient['allergenRisk']}"),
                        Text("Common Uses: ${ingredient['commonUses']}"),
                        if (ingredient['allergenMatch'] != null &&
                            ingredient['allergenMatch'].isNotEmpty)
                          Text("Allergens: ${ingredient['allergenMatch'].join(', ')}"),
                        ..._buildSubstitutionWidgets(ingredient['allergenMatch']),

                        Row(
                          children: [
                            TextButton(
                              onPressed: () async {
                                setState(() {
                                  if (isSafeMarked) {
                                    _userSafeIngredients.remove(name);
                                  } else {
                                    _userSafeIngredients.add(name);
                                    _userAvoidIngredients.remove(name);
                                  }
                                });
                                await _saveUserPreferences();
                              },
                              child: Text(isSafeMarked ? "Unmark Safe" : "Mark as Safe"),
                            ),
                            TextButton(
                              onPressed: () async {
                                setState(() {
                                  if (isAvoidMarked) {
                                    _userAvoidIngredients.remove(name);
                                  } else {
                                    _userAvoidIngredients.add(name);
                                    _userSafeIngredients.remove(name);
                                  }
                                });
                                await _saveUserPreferences();
                              },
                              child: Text(isAvoidMarked ? "Unmark Avoid" : "Mark as Avoid"),
                            ),
                          ],
                        ),
                      ],
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ), ); } }
