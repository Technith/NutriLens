import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nutrilensfire/pages/tracker_page.dart';

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

  Future<void> _pickImageAndRecognizeText() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();
      List<String> ingredients = recognizedText.text.split(',');
      ingredients = ingredients
          .map((item) =>
          item
              .replaceAll(RegExp(r'\bIngredients\b', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim()
      )
          .toList();

      DatabaseReference ref = FirebaseDatabase.instance.ref(
          "Ingredients");
      var snapshot = await ref.get();
      Map<String, String> dict = {};
      for (String ingredient_name in ingredients) {
        for (DataSnapshot ingredient in snapshot.children) {
          String name = ingredient.child("IngredientName").value.toString();
          if (name.trim().toUpperCase() == ingredient_name.trim().toUpperCase()) {
            dict[ingredient_name] = ingredient.child("Warnings").value.toString();
            break;
          }
        }
        if (!dict.containsKey(ingredient_name)) {
          dict[ingredient_name] = "No warnings found";
        }
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Recognized Text"),
          content: SingleChildScrollView(child: Text(dict.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
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
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Image to Text (OCR)"),
                onPressed: _pickImageAndRecognizeText,
              ),
            )
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

  Set<String> _userAllergenPreferences = {};

  final String translationUrl = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=en&dt=t&q=';

  final Map<String, List<String>> _allergenKeywordMap = { //failsafe in case if ingredient isnt found in base
    "peanut": [
      "peanut", "peanuts", "roasted peanuts", "groundnut", "arachis", "peanut butter",
      "peanut flour", "peanut oil", "crushed peanuts"
    ],
    "tree nut": [
      "tree nut", "almond", "walnut", "cashew", "pecan", "hazelnut", "macadamia",
      "pine nut", "brazil nut", "nut paste", "nut butter", "nut oil", "mixed nuts"
    ],
    "milk": [
      "milk", "whole milk", "skim milk", "cream", "buttermilk", "cheese", "curd",
      "casein", "caseinate", "whey", "lactose", "dairy", "yogurt", "milk solids", "milk protein"
    ],
    "wheat": [
      "wheat", "whole wheat", "semolina", "durum", "spelt", "farro", "bulgur",
      "einkorn", "couscous", "graham flour", "wheat flour", "wheat starch"
    ],
    "gluten": [
      "gluten", "barley", "rye", "malt", "triticale", "brewer's yeast",
      "malted barley", "hydrolyzed wheat protein", "malt extract", "seitan"
    ],
    "shrimp": [
      "shrimp", "prawn", "prawns", "crustacean", "shell-on shrimp", "shrimp powder",
      "shrimp extract"
    ],
    "shellfish": [
      "shellfish", "crab", "lobster", "scallop", "clam", "mussel", "oyster",
      "crustaceans", "shellfish extract", "shellfish powder"
    ],
    "hazelnut": [
      "hazelnut", "hazelnuts", "filbert", "filberts", "hazelnut flour", "hazelnut oil"
    ],
    "oats": [
      "oat", "oats", "oatmeal", "rolled oats", "steel-cut oats", "instant oats", "oat bran", "oat flour"
    ],
    "legumes": [
      "legume", "legumes", "lentil", "lentils", "soy", "soybean", "soybeans",
      "green pea", "split pea", "mung bean", "mung beans", "black-eyed pea", "pigeon pea", "broad beans"
    ],
    "chickpeas": [
      "chickpea", "chickpeas", "garbanzo", "garbanzo bean", "garbanzo flour", "chana", "gram flour"
    ],
    "mustard": [
      "mustard", "mustard seed", "mustard flour", "yellow mustard", "brown mustard",
      "mustard oil", "dijon", "mustard extract", "mustard greens"
    ],
    "sunflower seeds": [
      "sunflower seed", "sunflower seeds", "sunflower kernel", "sunflower oil", "sunflower lecithin"
    ],
    "banana": [
      "banana", "bananas", "plantain", "plantains", "banana flour", "dried banana", "banana puree"
    ]
  };

  @override
  void initState() {
    super.initState();
    fetchProductData();
    _loadUserAllergenPreferences();
  }

  Future<void> _loadUserAllergenPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref("Users/${user.uid}/AllergenPreferences");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _userAllergenPreferences = data.keys.map((e) => e.toLowerCase().trim()).toSet();
      });
    }
  }

  Future<String> translateToEnglish(String text) async {
    final cacheBox = await Hive.openBox('translationCache');
    if (cacheBox.containsKey(text)) return cacheBox.get(text);

    final encoded = Uri.encodeComponent(text);
    final url = '$translationUrl$encoded';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final translated = result[0][0][0];
        cacheBox.put(text, translated);
        return translated;
      }
    } catch (e) {
      debugPrint("❌ Translation error for '$text': $e");
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
        await _logScanToHistory();
        _translateIngredientsInBackground();
        _showAllergenAlertFromText();
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
      await _logScanToHistory();
      _translateIngredientsInBackground();
      _showAllergenAlertFromText();
    } catch (e) {
      setState(() {
        errorMessage = "❌ Unexpected error: $e";
        isLoading = false;
      });
    }
  }

  void _showAllergenAlertFromText() {
    if (productData == null || _userAllergenPreferences.isEmpty) return;

    final ingredients = productData!['ingredients'];
    final Set<String> triggeredAllergens = {};
    final Set<String> matchedKeywords = {};

    for (final ingredient in ingredients) {
      final rawText = (ingredient['text_en'] ?? ingredient['text'] ?? "").toString().toLowerCase();

      for (final allergen in _userAllergenPreferences) {
        final keywords = _allergenKeywordMap[allergen.toLowerCase()] ?? [];
        for (final keyword in keywords) {
          if (rawText.contains(keyword)) {
            triggeredAllergens.add(allergen);
            matchedKeywords.add(keyword);
          }
        }
      }
    }

    if (triggeredAllergens.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⚠️ Allergen Alert"),
          content: Text(
            "ALLERGEN ALERT!!!:\n\n"
                "Matched allergens: ${triggeredAllergens.join(', ')}\n"
                "Detected keywords: ${matchedKeywords.join(', ')}",
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
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

  Future<void> _logScanToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || productData == null) return;

    final dbRef = FirebaseDatabase.instance.ref("HistoryLog/${user.uid}");
    final now = DateTime.now().toUtc();
    final timestamp = now.toIso8601String().split('.').first + 'Z';
    final barcode = widget.barcode;

    final snapshot = await dbRef.get();
    for (final entry in snapshot.children) {
      final String? existingTimeStr = entry.key;
      if (existingTimeStr == null) continue;

      final existingData = entry.value as Map;
      final existingBarcode = existingData["Barcode"];

      if (existingBarcode == barcode) {
        try {
          final existingTime = DateTime.parse(existingTimeStr);
          final sameDay = existingTime != null &&
              now.year == existingTime.year &&
              now.month == existingTime.month &&
              now.day == existingTime.day;


          if (sameDay) {
            debugPrint("⏱ Duplicate barcode scanned today. Skipping.");
            return;
          }

        } catch (_) {
          continue;
        }
      }
    }

    final List ingredients = productData!['ingredients'] ?? [];
    final String combinedIngredients = ingredients
        .map((e) => (e['text_en'] ?? e['text'] ?? "").toString())
        .where((text) => text.isNotEmpty)
        .join(", ");

    final data = {
      "Product": productData!['product_name'] ?? "Unnamed Product",
      "Ingredients": combinedIngredients,
      "Overall Health Score": (5 + (Random().nextDouble() * 2)).toStringAsFixed(1),
      "Barcode": barcode,
    };

    await dbRef.child(timestamp).set(data);
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
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                label: const Text("Add to Calorie Count"),
                onPressed: () async {
                  barcodeAPI(widget.barcode);
                  await Future.delayed(const Duration(seconds: 1));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackerPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
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
                      ? (translated.toString().isNotEmpty
                      ? translated
                      : "⚠️ Not translated: $original")
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
