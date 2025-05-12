import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool useManualEntry = false;
  final TextEditingController barcodeController = TextEditingController();

  void _handleBarcode(String code) {
    if (code.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsPage(barcode: code),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan or Enter Barcode")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("Use Manual Entry"),
              value: useManualEntry,
              onChanged: (value) {
                setState(() {
                  useManualEntry = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (useManualEntry)
              Column(
                children: [
                  TextField(
                    controller: barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Barcode',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _handleBarcode(barcodeController.text.trim());
                    },
                    child: const Text("Fetch Product"),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Open Camera Scanner"),
                  onPressed: () async {
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BarcodeScannerCameraPage(),
                      ),
                    );
                    if (scannedCode != null && scannedCode != "-1") {
                      _handleBarcode(scannedCode);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerCameraPage extends StatefulWidget {
  const BarcodeScannerCameraPage({super.key});

  @override
  State<BarcodeScannerCameraPage> createState() => _BarcodeScannerCameraPageState();
}

class _BarcodeScannerCameraPageState extends State<BarcodeScannerCameraPage> {
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
  bool isTranslating = false;
  bool showTranslated = true;
  Map<String, dynamic>? productData;
  String errorMessage = "";

  final List<String> translationUrls = [
    'https://libretranslate.de/translate',
    'https://translate.argosopentech.com/translate'
  ];

  @override
  void initState() {
    super.initState();
    fetchProductData();
  }

  Future<String> translateToEnglish(String text) async {
    final cacheBox = await Hive.openBox('translationCache');
    if (cacheBox.containsKey(text)) {
      return cacheBox.get(text);
    }

    for (final url in translationUrls) {
      try {
        final response = await http
            .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'q': text,
            'source': 'auto',
            'target': 'en',
            'format': 'text',
          }),
        )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final translated = data['translatedText'] ?? text;
          cacheBox.put(text, translated);
          return translated;
        }
      } catch (e) {
        debugPrint("❌ Translation error for '$text': $e using $url");
      }
    }

    return text;
  }

  Future<void> fetchProductData() async {
    final box = await Hive.openBox('productCache');
    try {
      if (box.containsKey(widget.barcode)) {
        productData = Map<String, dynamic>.from(box.get(widget.barcode));
        setState(() {
          isLoading = false;
        });
        _translateIngredientsInBackground();
        return;
      }

      final url = 'https://world.openfoodfacts.org/api/v0/product/${widget.barcode}.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = "❌ HTTP error: ${response.statusCode}";
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 0) {
        setState(() {
          errorMessage = "❌ Barcode not found in OpenFoodFacts";
          isLoading = false;
        });
        return;
      }

      productData = data['product'];
      box.put(widget.barcode, productData);
      setState(() {
        isLoading = false;
      });
      _translateIngredientsInBackground();
    } catch (e) {
      setState(() {
        errorMessage = "❌ Unexpected error: $e";
        isLoading = false;
      });
    }
  }

  void _translateIngredientsInBackground() async {
    if (productData?['ingredients'] == null || productData!['ingredients'] is! List) return;
    setState(() => isTranslating = true);

    final ingredients = productData!['ingredients'];
    bool changed = false;

    for (var ingredient in ingredients) {
      if (ingredient is Map && ingredient['text'] != null) {
        final original = ingredient['text'].toString().trim();
        final existing = ingredient['text_en']?.toString().trim();
        if (existing == null || existing.isEmpty || existing == original) {
          final translated = await translateToEnglish(original);
          ingredient['text_en'] = translated;
          changed = true;
          setState(() {});
        }
      }
    }

    if (changed) {
      final box = Hive.box('productCache');
      box.put(widget.barcode, productData);
    }

    setState(() => isTranslating = false);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productData?['product_name'] ?? "Unnamed Product",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text("Ingredients:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (isTranslating)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(),
              ),
            SwitchListTile(
              title: const Text("Show Translated Ingredients"),
              value: showTranslated,
              onChanged: (value) {
                setState(() {
                  showTranslated = value;
                });
              },
            ),
            Expanded(
              child: productData?['ingredients'] == null
                  ? const Text("No ingredients available.")
                  : ListView.builder(
                itemCount: productData!['ingredients'].length,
                itemBuilder: (context, index) {
                  final ingredient = productData!['ingredients'][index];
                  final original = ingredient['text'] ?? "Unnamed Ingredient";
                  final translated = ingredient['text_en'] ?? "";
                  final text = showTranslated
                      ? (translated.toString().isNotEmpty ? translated : "⚠️ Not translated: $original")
                      : original;

                  return ListTile(
                    title: Text(text),
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
