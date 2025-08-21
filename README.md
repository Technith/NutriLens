# Nutrilens

### Overview

Nutrilens is an Android mobile app built with **Flutter** that helps users read food labels using **OCR**, detect allergens, scan barcodes, fetch nutrition information from a local database, and track daily food consumption.

---

### Features

* **User Authentication** – Secure login and account management.
* **OCR Label Scanning** – Extracts text from food labels to identify allergens.
* **Barcode Scanning** – Retrieves nutrition facts from a database via UPC codes.
* **Nutrition Tracking** – Logs and tracks user consumption history.
* **Local Database Support** – Stores food and nutrition data for offline use.

---

### Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Firebase Authentication, Firebase Realtime Database, REST APIs
* **Libraries/Tools:** Google ML Kit (OCR), Barcode Scanner plugin
* **Version Control:** GitHub

---

### My Contributions

* Implemented **user login & authentication** with Firebase.
* Built **API integration** to fetch and populate local database with nutrition data.
* Developed **nutrition tracking system** for storing/retrieving food consumption history.
* Coordinated backend integration with frontend features (OCR, barcode scanning, allergen detection).

---

### Installation

1. Clone the repo:

   ```bash
   git clone https://github.com/BronsonHua1/NutriLens.git
   cd NutriLens
   ```
2. Install dependencies:

   ```bash
   flutter pub get
   ```
3. Run the app on an emulator or device:

   ```bash
   flutter run
   ```
