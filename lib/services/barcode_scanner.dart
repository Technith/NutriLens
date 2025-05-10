import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Barcode")),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty || barcodes.first.rawValue == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to scan barcode.")),
            );
            return;
          }
          final String code = barcodes.first.rawValue!;
          Navigator.pop(context, code); // Return scanned code to previous screen
        },
      ),
    );
  }
}
