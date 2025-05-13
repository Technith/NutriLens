import 'package:flutter/material.dart';
import 'barcode_scanner_page.dart';
import '../theme/theme_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: IconThemeData(color: ThemeColor.textPrimary),
        title: Text('Nutrilens', style: TextStyle(color: ThemeColor.textPrimary)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: ThemeColor.primary,
        foregroundColor: ThemeColor.textPrimary, // Text color
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 150,
              color: ThemeColor.textSecondary,
            ),
            SizedBox(height: 20),
            Text(
              'Scan now!',
              style: TextStyle(
                fontSize: 20,
                color: ThemeColor.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.qr_code_scanner, color: ThemeColor.textSecondary),
              label: Text("Start Scanner", style: TextStyle(color: ThemeColor.textSecondary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColor.primary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ThemeColor.background,
        currentIndex: 3, // Home index
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.settings, color: ThemeColor.textSecondary), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications, color: ThemeColor.textSecondary), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer,  color: ThemeColor.textSecondary), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home, color: ThemeColor.primary), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search,  color: ThemeColor.textSecondary), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person,  color: ThemeColor.textSecondary), label: ''),
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
