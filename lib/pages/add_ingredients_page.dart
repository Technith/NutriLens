import 'package:flutter/material.dart';
import '../services/local_ingredient_database_service.dart';

//stateful widget for adding and displaying ingredients
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
  final TextEditingController _allergenRiskController = TextEditingController();
  final TextEditingController _allergenMatchController = TextEditingController();
  final TextEditingController _commonUsesController = TextEditingController();
  final TextEditingController _dietaryTagsController = TextEditingController();
  final TextEditingController _healthImpactController = TextEditingController();
  final TextEditingController _warningsController = TextEditingController();

  List<Map<String, dynamic>> _ingredients = [];

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
    final allergenRisk = _allergenRiskController.text.trim().toLowerCase() == 'true';
    final allergenMatch = _allergenMatchController.text.trim().split(',');
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
          allergenRisk: allergenRisk,
          allergenMatch: allergenMatch,
          commonUses: commonUses,
          dietaryTags: dietaryTags,
          healthImpact: healthImpact,
          warnings: warnings,
        );

        _nameController.clear();
        _descriptionController.clear();
        _healthRatingController.clear();
        _categoryController.clear();
        _allergenRiskController.clear();
        _allergenMatchController.clear();
        _commonUsesController.clear();
        _dietaryTagsController.clear();
        _healthImpactController.clear();
        _warningsController.clear();

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
      appBar: AppBar(
        title: const Text('Add Ingredients'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: _healthRatingController, decoration: const InputDecoration(labelText: 'Health Rating (1-10)'), keyboardType: TextInputType.number),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
            TextField(controller: _allergenRiskController, decoration: const InputDecoration(labelText: 'Allergen Risk (true/false)')),
            TextField(controller: _allergenMatchController, decoration: const InputDecoration(labelText: 'Allergen Match (comma-separated)')),
            TextField(controller: _commonUsesController, decoration: const InputDecoration(labelText: 'Common Uses (comma-separated)')),
            TextField(controller: _dietaryTagsController, decoration: const InputDecoration(labelText: 'Dietary Tags (comma-separated)')),
            TextField(controller: _healthImpactController, decoration: const InputDecoration(labelText: 'Health Impact')),
            TextField(controller: _warningsController, decoration: const InputDecoration(labelText: 'Warnings')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addIngredient,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Add Ingredient', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = _ingredients[index];
                  return ListTile(
                    title: Text(ingredient['name'] ?? 'Unnamed'),
                    subtitle: Text('Health Rating: ${ingredient['healthRating']} - ${ingredient['category']}'),
                    onTap: () {
                      _showIngredientDetails(ingredient);
                    },
                  );
                },
              ),
            ),
          ],
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