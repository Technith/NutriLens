import 'package:flutter/material.dart';

class AllergenInfo extends StatelessWidget {
  const AllergenInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allergen Information'),
      ),
      body: const Center(
        child: Text('Details about Allergens'),
      ),
    );
  }
}
