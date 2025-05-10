import 'package:flutter/material.dart';

class DealDetailPage extends StatelessWidget {
  final Map<String, dynamic> deal;

  const DealDetailPage({Key? key, required this.deal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? imageUrl = deal['image_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(deal['title'] ?? 'Product Details'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                  },
                )
                    : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // Product Title
            Text(
              deal['title'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Brand
            Text(
              'Brand: ${deal['brand'] ?? 'Unknown Brand'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Store
            Text(
              'Store: ${deal['store'] ?? 'Various stores'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Discount
            Text(
              'Discount: ${deal['discount'] ?? '5'}% OFF',
              style: const TextStyle(fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Categories
            Text(
              'Categories: ${deal['categories'] ?? ''}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
