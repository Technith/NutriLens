import 'package:flutter/material.dart';

class CalorieGoalPage extends StatelessWidget {
  const CalorieGoalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Goal'),
      ),
      body: const Center(
        child: Text('Details about Calorie Goals'),
      ),
    );
  }
}
