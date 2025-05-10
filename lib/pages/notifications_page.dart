import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _searchQuery = '';
  String _sortOption = 'Newest First';
  String _filterOption = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationService>(context, listen: false).fetchRecalls();
    });
  }

  @override
  Widget build(BuildContext context) {
    var notificationService = Provider.of<NotificationService>(context);
    var recalls = notificationService.recalls;

    /// **1️⃣ Apply Search Functionality**
    List<Map<String, dynamic>> filteredRecalls = recalls.where((recall) {
      return recall['product'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          recall['reason'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    /// **2️⃣ Apply Sorting**
    if (_sortOption == 'Newest First') {
      filteredRecalls.sort((a, b) => b['date'].compareTo(a['date']));
    } else if (_sortOption == 'Oldest First') {
      filteredRecalls.sort((a, b) => a['date'].compareTo(b['date']));
    } else if (_sortOption == 'Alphabetical (A-Z)') {
      filteredRecalls.sort((a, b) => a['product'].compareTo(b['product']));
    }

    /// **3️⃣ Apply Filtering**
    if (_filterOption == 'Past 7 Days') {
      filteredRecalls = filteredRecalls.where((recall) {
        DateTime recallDate = DateTime.parse(recall['date']);
        return recallDate.isAfter(DateTime.now().subtract(Duration(days: 7)));
      }).toList();
    } else if (_filterOption == 'Past 30 Days') {
      filteredRecalls = filteredRecalls.where((recall) {
        DateTime recallDate = DateTime.parse(recall['date']);
        return recallDate.isAfter(DateTime.now().subtract(Duration(days: 30)));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              Provider.of<NotificationService>(context, listen: false).fetchRecalls();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          /// **🔍 Search Bar**
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search Recalls...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          /// **🔽 Sorting & Filtering Dropdowns**
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// **Sorting Dropdown**
                DropdownButton<String>(
                  value: _sortOption,
                  items: ['Newest First', 'Oldest First', 'Alphabetical (A-Z)']
                      .map((sort) => DropdownMenuItem(value: sort, child: Text(sort)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _sortOption = value!;
                    });
                  },
                ),

                /// **Filtering Dropdown**
                DropdownButton<String>(
                  value: _filterOption,
                  items: ['All', 'Past 7 Days', 'Past 30 Days']
                      .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterOption = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          /// **📜 List of Recalls (Filtered & Sorted)**
          Expanded(
            child: filteredRecalls.isEmpty
                ? Center(child: Text("No recalls found"))
                : ListView.builder(
              itemCount: filteredRecalls.length,
              itemBuilder: (context, index) {
                var recall = filteredRecalls[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      "⚠️ ${recall['product']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    subtitle: Text("Reason: ${recall['reason']}\nDate: ${recall['date']}"),
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
