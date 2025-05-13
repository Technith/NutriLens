import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/theme_colors.dart';
import '../services/color_theme_service.dart';
import '../theme/theme_colors.dart';

class DietaryPreferencesPage extends StatefulWidget {
  const DietaryPreferencesPage({Key? key}) : super(key: key);

  @override
  _DietaryPreferencesPageState createState() => _DietaryPreferencesPageState();
}

class _DietaryPreferencesPageState extends State<DietaryPreferencesPage> {
  final List<String> _availablePreferences = [
    "vegan", "vegetarian", "gluten_free", "keto", "paleo"
  ];

  Set<String> _selectedPreferences = {};

  final Map<String, List<String>> dietaryRules = {
    'vegan': ['fruit', 'vegetable', 'plant-based', 'grain', 'legume protein'],
    'vegetarian': ['dairy', 'egg', 'fruit', 'vegetable', 'grain'],
    'keto': ['oil', 'fat', 'meat', 'seafood flavoring', 'nut'],
    'gluten_free': ['fruit', 'vegetable', 'meat', 'seafood', 'sweetener', 'spice'],
    'paleo': ['meat', 'fruit', 'vegetable', 'nut', 'seed', 'spice'],
  };

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/DietaryPreferences");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _selectedPreferences = Set<String>.from(data.keys.map((e) => e.toLowerCase()));
      });
    }
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/DietaryPreferences");
    await ref.set({for (var p in _selectedPreferences) p: true});
  }

  Future<void> tagAllIngredientsWithDietaryTags() async {
    final dbRef = FirebaseDatabase.instance.ref('Ingredients');
    final snapshot = await dbRef.get();

    if (!snapshot.exists) return;

    final ingredients = Map<String, dynamic>.from(snapshot.value as Map);
    for (final entry in ingredients.entries) {
      final id = entry.key;
      final data = Map<String, dynamic>.from(entry.value);
      final category = (data['Category'] ?? '').toString().toLowerCase().trim();
      final tags = <String>[];

      dietaryRules.forEach((diet, allowedCategories) {
        if (allowedCategories.contains(category)) {
          tags.add(diet);
        }
      });

      if (tags.isEmpty) {
        tags.add("none");
      }

      await dbRef.child(id).update({'DietaryTags': tags});
    }

    SnackBar(
      content: Text("✅ Ingredients updated with dietary tags.", style: TextStyle(color: ThemeColor.textPrimary)),
      backgroundColor: ThemeColor.secondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text('Nutrilens', style: TextStyle(color: ThemeColor.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ThemeColor.background,
        foregroundColor: ThemeColor.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: _availablePreferences.map((preference) {
                  final isSelected = _selectedPreferences.contains(preference.toLowerCase());
                  return CheckboxListTile(
                    title: Text(
                      preference[0].toUpperCase() + preference.substring(1),
                      style: TextStyle(color: ThemeColor.textPrimary),
                    ),
                    value: isSelected,
                    onChanged: (bool? selected) async {
                      setState(() {
                        if (selected == true) {
                          _selectedPreferences.add(preference.toLowerCase());
                        } else {
                          _selectedPreferences.remove(preference.toLowerCase());
                        }
                      });
                      await _savePreferences();
                    },
                    activeColor: ThemeColor.primary,
                    checkColor: ThemeColor.background,
                    side: BorderSide(color: ThemeColor.primary),
                  );
                }).toList(),
              ),
            ),
            ElevatedButton(
              onPressed: tagAllIngredientsWithDietaryTags,
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColor.primary,
              ),
              child: Text(
                "Refresh Ingredients Dietary Info",
                style: TextStyle(color: ThemeColor.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}