import 'package:flutter/material.dart';

class HistoryLogPage extends StatelessWidget {
  const HistoryLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
      ),
      body: const Center(
        child: Text('Details about History Log'),
      ),
    );
  }
}
