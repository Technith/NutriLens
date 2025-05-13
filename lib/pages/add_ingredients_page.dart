import 'package:flutter/material.dart';
import '../services/local_ingredient_database_service.dart';
import '../theme/theme_colors.dart';

class AddIngredientsPage extends StatefulWidget {
  const AddIngredientsPage({super.key});

  @override
  _AddIngredientsPageState createState() => _AddIngredientsPageState();
}

class _AddIngredientsPageState extends State<AddIngredientsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _healthRatingController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _commonUsesController = TextEditingController();
  final TextEditingController _dietaryTagsController = TextEditingController();
  final TextEditingController _healthImpactController = TextEditingController();
  final TextEditingController _warningsController = TextEditingController();

  bool _allergenRisk = false;
  final List<String> _allAvailableAllergens = [
    "Peanut", "Tree nut", "Milk", "Wheat", "Gluten", "Shrimp",
    "Shellfish", "Hazelnut", "Oats", "Legumes", "Chickpeas",
    "Mustard", "Sunflower seeds", "Banana"
  ];
  final Set<String> _selectedAllergens = {};

  List<Map<String, dynamic>> _ingredients = [];
  bool _showUploaded = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final ingredients = await IngredientDatabase.instance.getIngredients();
    setState(() {
      _ingredients = ingredients;
    });
  }

  Future<void> _addIngredient() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final healthRatingText = _healthRatingController.text.trim();
    final category = _categoryController.text.trim();
    final commonUses = _commonUsesController.text.trim().split(',');
    final dietaryTags = _dietaryTagsController.text.trim().split(',');
    final healthImpact = _healthImpactController.text.trim();
    final warnings = _warningsController.text.trim();

    if (name.isNotEmpty && description.isNotEmpty && healthRatingText.isNotEmpty && category.isNotEmpty) {
      final healthRating = int.tryParse(healthRatingText);
      if (healthRating != null) {
        await IngredientDatabase.instance.insertIngredient(
          name: name,
          description: description,
          healthRating: healthRating,
          category: category,
          allergenRisk: _allergenRisk,
          allergenMatch: _selectedAllergens.toList(),
          commonUses: commonUses,
          dietaryTags: dietaryTags,
          healthImpact: healthImpact,
          warnings: warnings,
        );

        _nameController.clear();
        _descriptionController.clear();
        _healthRatingController.clear();
        _categoryController.clear();
        _commonUsesController.clear();
        _dietaryTagsController.clear();
        _healthImpactController.clear();
        _warningsController.clear();
        _selectedAllergens.clear();
        _allergenRisk = false;

        _loadIngredients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health Rating must be a number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        title: const Text('Add Ingredients'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ThemeColor.background,
        foregroundColor: ThemeColor.textPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showUploaded = !_showUploaded;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _showUploaded ? 'Hide Uploaded Ingredients' : 'View Uploaded Ingredients',
                  style: TextStyle(color: ThemeColor.textPrimary),
                ),
              ),
              const SizedBox(height: 20),
              if (_showUploaded)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: ThemeColor.background,
                    border: Border.all(color: ThemeColor.textSecondary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return Card(
                        elevation: 2,
                        color: ThemeColor.secondary, // Optional: for slight contrast
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            ingredient['name'] ?? 'Unnamed',
                            style: TextStyle(color: ThemeColor.textPrimary),
                          ),
                          subtitle: Text(
                            'Health Rating: ${ingredient['healthRating']} - ${ingredient['category']}',
                            style: TextStyle(color: ThemeColor.textSecondary),
                          ),
                          onTap: () => _showIngredientDetails(ingredient),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              TextField(
                controller: _descriptionController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              TextField(
                controller: _healthRatingController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Health Rating (1-10)', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _categoryController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                title: Text(
                  'Allergen Risk',
                  style: TextStyle(color: ThemeColor.textPrimary),
                ),
                value: _allergenRisk,
                onChanged: (val) => setState(() => _allergenRisk = val),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text(
                    'Select Allergens',
                    style: TextStyle(color: ThemeColor.textPrimary),
                  ),
                ),
              ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _allAvailableAllergens.map((allergen) {
                  return CheckboxListTile(
                    title: Text(
                      allergen,
                      style: TextStyle(color: ThemeColor.textPrimary),
                    ),
                    value: _selectedAllergens.contains(allergen.toLowerCase()),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedAllergens.add(allergen.toLowerCase());
                        } else {
                          _selectedAllergens.remove(allergen.toLowerCase());
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              TextField(
                controller: _commonUsesController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Common Uses (comma-sepersate)', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              TextField(
                controller: _dietaryTagsController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Dietary Tags (comma-separated)', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              TextField(
                controller: _healthImpactController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Health Impact', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              TextField(
                controller: _warningsController,
                style: TextStyle(color: ThemeColor.textPrimary),
                decoration: InputDecoration(labelText: 'Warnings', labelStyle: TextStyle(color: ThemeColor.textSecondary),),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addIngredient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Add Ingredient', style: TextStyle(color: ThemeColor.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIngredientDetails(Map<String, dynamic> ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ingredient['name'] ?? 'No Name'),
        content: SingleChildScrollView(
          child: Text(
            'Description: ${ingredient['description'] ?? ''}\n\n'
                'Health Rating: ${ingredient['healthRating'] ?? ''}\n\n'
                'Category: ${ingredient['category'] ?? ''}\n\n'
                'Allergen Risk: ${ingredient['allergenRisk'] ?? ''}\n'
                'Allergen Match: ${(ingredient['allergenMatch'] as List?)?.join(", ") ?? ''}\n\n'
                'Common Uses: ${(ingredient['commonUses'] as List?)?.join(", ") ?? ''}\n'
                'Dietary Tags: ${(ingredient['dietaryTags'] as List?)?.join(", ") ?? ''}\n\n'
                'Health Impact: ${ingredient['healthImpact'] ?? ''}\n'
                'Warnings: ${ingredient['warnings'] ?? ''}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () async {
              await IngredientDatabase.instance.deleteIngredient(ingredient['id']);
              Navigator.pop(context);
              _loadIngredients();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}