import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryLogPage extends StatefulWidget {
  const HistoryLogPage({super.key});


  @override
  State<HistoryLogPage> createState() => _HistoryLogPageState();
}

class _HistoryLogPageState extends State<HistoryLogPage> {
  Map<String, dynamic> _historyData = {};
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is logged in, show an empty history or redirect
      setState(() {
        _historyData = {};
      });
      return;
    }

    final uid = user.uid;
    final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('HistoryLog/$uid');

    final event = await _historyRef.once();

    if (event.snapshot.exists) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        _historyData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dates = _historyData.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // sort latest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
        backgroundColor: Colors.green,
      ),
      body: _historyData.isEmpty
          ? const Center(child: Text("No history available."))
          : ListView.builder(
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final entry = Map<String, dynamic>.from(_historyData[date]);
          final isExpanded = _expandedIndex == index;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              title: Text(entry['Product'] ?? 'Unknown Product'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date),
                  if (isExpanded) const SizedBox(height: 8),
                  if (isExpanded)
                    Text("Ingredients: ${entry['Ingredients'] ?? 'Unknown'}"),
                  if (isExpanded)
                    Text("Overall Health Score: ${entry['Overall Health Score'] ?? 'N/A'}"),
                ],
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() {
                  _expandedIndex = isExpanded ? null : index;
                });
              },
            ),
          );
        },
      ),
    );
  }
}