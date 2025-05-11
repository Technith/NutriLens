import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'home_page.dart';

void BarcodeScanner() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('productCache');
  await Hive.openBox('translationCache');
  await Hive.openBox('settingsBox');
  runApp(const ScannerHome());
}

class ScannerHome extends StatelessWidget {
  const ScannerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrilens',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nutrilens")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final scannedCode = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
            );
            if (scannedCode != null && scannedCode != "-1") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(barcode: scannedCode),
                ),
              );
            }
          },
          child: const Text("Scan Barcode"),
        ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan a Barcode")),
      body: MobileScanner(
        onDetect: (barcodeCapture) {
          if (barcodeCapture.barcodes.isEmpty || !isScanning) return;
          setState(() {
            isScanning = false;
          });
          final String? code = barcodeCapture.barcodes.first.rawValue;
          if (code != null) {
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}

class ProductDetailsPage extends StatefulWidget {
  final String barcode;
  const ProductDetailsPage({super.key, required this.barcode});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool isLoading = true;
  Map<String, dynamic>? productData;
  String errorMessage = "";
  bool showTranslated = true;

  @override
  void initState() {
    super.initState();
    loadToggleState();
    fetchProductData();
  }

  Future<void> loadToggleState() async {
    final settingsBox = Hive.box('settingsBox');
    setState(() {
      showTranslated = settingsBox.get('showTranslated', defaultValue: true);
    });
  }

  Future<void> saveToggleState(bool value) async {
    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('showTranslated', value);
  }

  Future<String> translateToEnglish(String text) async {
    final cacheBox = Hive.box('translationCache');
    if (cacheBox.containsKey(text)) {
      return cacheBox.get(text);
    }

    final uri = Uri.parse('https://libretranslate.com/translate');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'q': text,
          'source': 'auto',
          'target': 'en',
          'format': 'text',
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['translatedText'] ?? text;
        cacheBox.put(text, translatedText);
        return translatedText;
      }
    } catch (e) {
      debugPrint("Translation API failed for '$text': $e");
    }
    return text;
  }

  Future<void> fetchProductData() async {
    final box = Hive.box('productCache');
    if (box.containsKey(widget.barcode)) {
      productData = Map<String, dynamic>.from(box.get(widget.barcode));
      await _translateIngredientsSafely();
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = 'https://world.openfoodfacts.org/api/v0/product/${widget.barcode}.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1) {
          productData = data['product'];
          await _translateIngredientsSafely();
          box.put(widget.barcode, productData);
          setState(() {
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = "Product not found.";
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Error fetching product data.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _translateIngredientsSafely() async {
    if (productData?['ingredients'] != null && productData!['ingredients'] is List) {
      for (var ingredient in productData!['ingredients']) {
        try {
          if (ingredient is Map && ingredient['text'] != null && ingredient['text_en'] == null) {
            final translated = await translateToEnglish(ingredient['text']);
            ingredient['text_en'] = translated;
          }
        } catch (e) {
          debugPrint("Translation error for ingredient: $e");
        }
      }
    } else {
      debugPrint("No ingredients available to translate.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productData?['product_name'] ?? "Unnamed Product",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ingredients:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Show Translated Ingredients"),
              value: showTranslated,
              onChanged: (value) {
                setState(() {
                  showTranslated = value;
                });
                saveToggleState(value);
              },
            ),
            Expanded(
              child: productData?['ingredients'] == null
                  ? const Text("No ingredients available.")
                  : ListView.builder(
                itemCount: productData!['ingredients'].length,
                itemBuilder: (context, index) {
                  final ingredient = productData!['ingredients'][index];
                  final text = showTranslated
                      ? ingredient['text_en'] ?? ingredient['text']
                      : ingredient['text'];
                  return ListTile(
                    title: Text(text ?? "Unnamed Ingredient"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}