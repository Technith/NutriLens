import 'package:flutter/material.dart';

class IngredientsProfilePage extends StatelessWidget {
  const IngredientsProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredients Profile'),
      ),
      body: const Center(
        child: Text('Details about Ingredients Profile'),
      ),
    );
  }
}
