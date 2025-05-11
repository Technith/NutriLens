import 'package:flutter/material.dart';
import 'barcode_scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrilens'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 150,
              color: Colors.black,
            ),
            SizedBox(height: 20),
            Text(
              'Scan now!',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner),
              label: Text("Start Scanner"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Home index
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.green), label: ''),
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
            Navigator.pushNamed(context, '/home');
          } else if (index == 4) {
            Navigator.pushNamed(context, '/search');
          } else if (index == 5) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }
}
