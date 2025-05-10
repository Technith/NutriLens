import 'package:flutter/material.dart';
import '../services/openfood_deals_service.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({Key? key}) : super(key: key);

  @override
  _DealsPageState createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> {
  final OpenFoodDealsService _dealsService = OpenFoodDealsService();
  List<Map<String, dynamic>> _deals = [];
  String _currentCategory = 'snacks';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  // Load deals: try cache first, then fetch new if needed
  Future<void> _loadDeals() async {
    setState(() {
      _isLoading = true;
    });

    final deals = await _dealsService.fetchGroceryDeals(category: _currentCategory);

    setState(() {
      _deals = deals;
      _isLoading = false;
    });
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null) {
      setState(() {
        _currentCategory = newCategory;
      });
      _loadDeals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Deals'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Category dropdown
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
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 20),
                  Text('Fetching grocery deals...')
                ],
              ),
            )
                : _deals.isEmpty
                ? const Center(
              child: Text(
                '😢 No deals found. Try another category!',
                style: TextStyle(fontSize: 18),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadDeals,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _deals.length,
                itemBuilder: (context, index) {
                  final deal = _deals[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.green[50],
                        child: Icon(Icons.shopping_cart, color: Colors.green[800]),
                      ),
                      title: Text(
                        deal['title'] ?? 'Unknown Product',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(deal['brand'] ?? 'Unknown Brand'),
                          const SizedBox(height: 4),
                          Text(
                            'Store: ${deal['store'] ?? 'Various stores'}',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${deal['discount'] ?? '5'}% OFF',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer, color: Colors.green), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/settings');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/notifications');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/deals');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
