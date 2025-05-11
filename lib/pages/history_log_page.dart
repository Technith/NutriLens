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
  String _searchQuery = '';
  String _dateFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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

  void _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    await FirebaseDatabase.instance.ref('HistoryLog/$uid').remove();

    setState(() {
      _historyData = {};
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ History log cleared.")),
    );
  }

  List<String> _filteredDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _historyData.entries.where((entry) {
      final dateTime = DateTime.tryParse(entry.key);
      if (dateTime == null) return false;

      if (_dateFilter == 'today') {
        return dateTime.isAfter(today);
      } else if (_dateFilter == 'week') {
        return dateTime.isAfter(startOfWeek);
      } else if (_dateFilter == 'month') {
        return dateTime.isAfter(startOfMonth);
      }
      return true; // 'all'
    }).where((entry) {
      if (_searchQuery.isEmpty) return true;
      final product = entry.value['Product']?.toString().toLowerCase() ?? '';
      final ingredients = entry.value['Ingredients']?.toString().toLowerCase() ?? '';
      return product.contains(_searchQuery.toLowerCase()) || ingredients.contains(_searchQuery.toLowerCase());
    }).map((entry) => entry.key).toList()
      ..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    final filteredDates = _filteredDates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Log'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products or ingredients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text("All"),
                  selected: _dateFilter == 'all',
                  onSelected: (_) => setState(() => _dateFilter = 'all'),
                ),
                FilterChip(
                  label: const Text("Today"),
                  selected: _dateFilter == 'today',
                  onSelected: (_) => setState(() => _dateFilter = 'today'),
                ),
                FilterChip(
                  label: const Text("This Week"),
                  selected: _dateFilter == 'week',
                  onSelected: (_) => setState(() => _dateFilter = 'week'),
                ),
                FilterChip(
                  label: const Text("This Month"),
                  selected: _dateFilter == 'month',
                  onSelected: (_) => setState(() => _dateFilter = 'month'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  onPressed: _clearHistory,
                  label: const Text("Clear History"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                )
              ],
            ),
          ),
          Expanded(
            child: _historyData.isEmpty
                ? const Center(child: Text("No history available."))
                : ListView.builder(
              itemCount: filteredDates.length,
              itemBuilder: (context, index) {
                final date = filteredDates[index];
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
          ),
        ],
      ),
    );
  }
}