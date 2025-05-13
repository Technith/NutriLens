import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/openfood_deals_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({Key? key}) : super(key: key);

  @override
  _DealsPageState createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final OpenFoodDealsService _dealsService = OpenFoodDealsService();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("grocery_deals");
  List<Map<String, dynamic>> _deals = [];
  String _currentCategory = 'snacks';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedDeals(); // Only load Firebase data by default
  }

  Future<void> _loadCachedDeals() async {
    setState(() => _isLoading = true);

    final snapshot = await _dbRef.child(_currentCategory).once();
    final data = snapshot.snapshot.value;

    if (data is Map) {
      _deals = data.values.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      _deals = [];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchFreshDeals() async {
    setState(() => _isLoading = true);

    final deals = await _dealsService.fetchGroceryDeals(category: _currentCategory);

    if (deals.isNotEmpty) {
      _deals = deals;
      final Map<String, dynamic> saveData = {
        for (var deal in deals) _dbRef.push().key!: deal,
      };
      await _dbRef.child(_currentCategory).set(saveData);
    }

    setState(() => _isLoading = false);
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null) {
      setState(() {
        _currentCategory = newCategory;
      });
      _loadCachedDeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Deals'),
        centerTitle: true,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFreshDeals,
            tooltip: 'Fetch Fresh Deals',
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<String>(
              value: _currentCategory,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'snacks', child: Text('Snacks')),
                DropdownMenuItem(value: 'beverages', child: Text('Drinks')),
                DropdownMenuItem(value: 'fruits', child: Text('Fruits')),
                DropdownMenuItem(value: 'vegetables', child: Text('Vegetables')),
              ],
              onChanged: _onCategoryChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _deals.isEmpty
                ? const Center(child: Text('No deals available.'))
                : RefreshIndicator(
              onRefresh: _fetchFreshDeals,
              child: ListView.builder(
                itemCount: _deals.length,
                itemBuilder: (context, index) {
                  final deal = _deals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: deal['image_url'] != null && deal['image_url'] != ''
                          ? Image.network(deal['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.shopping_cart),
                      title: Text(deal['title'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deal['brand'] ?? ''),
                          Text('Store: ${deal['store'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                          Text('${deal['discount']}% OFF', style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                      trailing: const Icon(Icons.local_offer, color: Colors.redAccent),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
