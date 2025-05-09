import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrilens',
      debugShowCheckedModeBanner: false,
      home: const Page(), // Using our uniquely named home widget
    );
  }
}

class Page extends StatelessWidget {
  const Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrilens Barcode Scanner"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Navigate to the barcode scanner page and await its result.
            final scannedCode = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
            );
            if (scannedCode != null && scannedCode != "-1") {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Scanned: $scannedCode")),
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

  // Request camera permission.
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
          // barcodeCapture is an instance of BarcodeCapture which contains a list of detected barcodes.
          if (barcodeCapture.barcodes.isEmpty || !isScanning) return;
          setState(() {
            isScanning = false; // Prevent multiple detections.
          });
          final String? code = barcodeCapture.barcodes.first.rawValue;
          if (code != null) {
            Navigator.pop(context, code); // Return the scanned code.
          }
        },
      ),
    );
  }
}