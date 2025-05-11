import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nutrilensfire/pages/glossary_page.dart';


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
      appBar: AppBar(
        title: const Text("Ingredient Safety Preferences"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Quick Ingredient Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    title: const Text("Ingredients with Allergen Risk"),
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
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
                    ],
                  ),
                );
              },
              child: const Text("All Ingredients with Allergen Risk"),
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
                    title: const Text("My Safe Ingredients"),
                    content: safeIngredients.isEmpty
                        ? const Text("No ingredients marked as safe.")
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: safeIngredients.map((e) => Text("\u2022 $e")).toList(),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
                    ],
                  ),
                );
              },
              child: loadingSafe ? const CircularProgressIndicator() : const Text("My Safe Ingredients"),
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
                    title: const Text("My Avoided Ingredients"),
                    content: avoidedIngredients.isEmpty
                        ? const Text("No ingredients marked as avoided.")
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: avoidedIngredients.map((e) => Text("\u2022 $e")).toList(),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
                    ],
                  ),
                );
              },
              child: loadingAvoided ? const CircularProgressIndicator() : const Text("My Avoided Ingredients"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final prefsRef = FirebaseDatabase.instance.ref("Users/${user.uid}/IngredientPreferences");
                  await prefsRef.remove();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ All marked ingredients have been cleared."),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
              ),
              child: const Text("Reset All Marked Ingredients"),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              "Select Allergens You React To",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontSize: 15),
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