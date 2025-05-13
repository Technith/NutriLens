import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nutrilensfire/pages/glossary_page.dart';
import '../theme/theme_colors.dart';

class AllergenInfo extends StatefulWidget {
  const AllergenInfo({Key? key}) : super(key: key);

  @override
  _AllergenInfoState createState() => _AllergenInfoState();
}

class _AllergenInfoState extends State<AllergenInfo> {
  List<String> safeIngredients = [];
  List<String> avoidedIngredients = [];
  bool loadingSafe = false;
  bool loadingAvoided = false;

  final List<String> _availableAllergens = [
    "peanut", "tree nut", "milk", "wheat", "gluten", "shrimp",
    "shellfish", "hazelnut", "oats", "legumes", "chickpeas",
    "mustard", "sunflower seeds", "banana"
  ];

  Set<String> _selectedAllergens = {};

  @override
  void initState() {
    super.initState();
    _loadSavedAllergens();
  }

  Future<void> _loadSavedAllergens() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _selectedAllergens = Set<String>.from(data.keys.map((e) => e.toLowerCase()));
      });
    }
  }

  Future<void> loadMarkedIngredients(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/IngredientPreferences/$type");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        if (type == 'safe') {
          safeIngredients = data.keys.toList();
        } else {
          avoidedIngredients = data.keys.toList();
        }
      });
    } else {
      setState(() {
        if (type == 'safe') safeIngredients = [];
        if (type == 'avoid') avoidedIngredients = [];
      });
    }
  }

  Future<void> _saveAllergenPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
    await ref.set({for (var a in _selectedAllergens) a: true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        title: const Text("Ingredient Safety Preferences"),
        backgroundColor: ThemeColor.background,
        foregroundColor: ThemeColor.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quick Ingredient Access",
              style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeColor.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final allergenRef = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
                final ingredientRef = FirebaseDatabase.instance.ref("Ingredients");

                final allergenSnap = await allergenRef.get();
                final ingredientSnap = await ingredientRef.get();

                if (!allergenSnap.exists || !ingredientSnap.exists) return;

                final userAllergens = Set<String>.from(
                  (Map<String, dynamic>.from(allergenSnap.value as Map)).keys.map((e) => e.toLowerCase().trim()),
                );

                final ingredientData = Map<String, dynamic>.from(ingredientSnap.value as Map);
                final matchingIngredients = <String>[];

                ingredientData.forEach((key, value) {
                  final matches = value['AllergenMatch'] ?? [];
                  final ingredientAllergens = List<String>.from(matches.map((e) => e.toLowerCase().trim()));
                  final hasMatch = ingredientAllergens.any((a) => userAllergens.contains(a));
                  if (hasMatch) {
                    matchingIngredients.add(value['IngredientName'] ?? 'Unknown');
                  }
                });

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ThemeColor.background,
                    title: Text("Ingredients with Allergen Risk", style: TextStyle(color: ThemeColor.textPrimary)),
                    content: matchingIngredients.isEmpty
                        ? const Text("No ingredients match your allergen preferences.")
                        : SizedBox(
                      width: double.maxFinite,
                      child: ListView(
                        shrinkWrap: true,
                        children: matchingIngredients.map((e) => Text("• $e")).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: ThemeColor.primary))),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.primary),
              child: Text("All Ingredients with Allergen Risk", style: TextStyle(color: ThemeColor.textPrimary)),
            ),

            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                setState(() => loadingSafe = true);
                await loadMarkedIngredients('safe');
                setState(() => loadingSafe = false);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ThemeColor.background,
                    title: Text("My Safe Ingredients", style: TextStyle(color: ThemeColor.textPrimary)),
                    content: safeIngredients.isEmpty
                        ? Text("No ingredients marked as safe.", style: TextStyle(color: ThemeColor.textSecondary))
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: safeIngredients.map((e) => Text("\u2022 $e", style: TextStyle(color: ThemeColor.textSecondary))).toList(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Close", style: TextStyle(color: ThemeColor.primary)),
                      )
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.primary),
              child: loadingSafe
                  ? const CircularProgressIndicator()
                  : Text("My Safe Ingredients", style: TextStyle(color: ThemeColor.textPrimary)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                setState(() => loadingAvoided = true);
                await loadMarkedIngredients('avoid');
                setState(() => loadingAvoided = false);
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ThemeColor.background,
                    title: Text("My Avoided Ingredients", style: TextStyle(color: ThemeColor.textPrimary)),
                    content: avoidedIngredients.isEmpty
                        ? Text("No ingredients marked as avoided.", style: TextStyle(color: ThemeColor.textSecondary))
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: avoidedIngredients.map((e) => Text("• $e", style: TextStyle(color: ThemeColor.textSecondary)))
                          .toList(),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: ThemeColor.primary)),)
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: ThemeColor.primary),
              child: loadingAvoided
                  ? const CircularProgressIndicator()
                  : Text("My Avoided Ingredients", style: TextStyle(color: ThemeColor.textPrimary)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final prefsRef = FirebaseDatabase.instance.ref("Users/${user.uid}/IngredientPreferences");
                  await prefsRef.remove();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: ThemeColor.secondary,
                      content: Text("✅ All marked ingredients have been cleared.",
                          style: TextStyle(color: ThemeColor.textPrimary)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
              ),
              child: Text("Reset All Marked Ingredients", style: TextStyle(color: ThemeColor.textPrimary)),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            Text(
              "Select Allergens You React To",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColor.textPrimary),
            ),
            const SizedBox(height: 10),
            Column(
              children: _availableAllergens.map((allergen) {
                final isSelected = _selectedAllergens.contains(allergen.toLowerCase());
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: CheckboxListTile(
                    title: Text(
                      allergen[0].toUpperCase() + allergen.substring(1),
                      style: TextStyle(fontSize: 15, color: ThemeColor.textSecondary),
                    ),
                    value: isSelected,
                    onChanged: (bool? selected) async {
                      setState(() {
                        if (selected == true) {
                          _selectedAllergens.add(allergen.toLowerCase());
                        } else {
                          _selectedAllergens.remove(allergen.toLowerCase());
                        }
                      });
                      await _saveAllergenPreferences();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}