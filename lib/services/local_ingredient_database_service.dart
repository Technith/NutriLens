import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class IngredientDatabase {
  static final IngredientDatabase instance = IngredientDatabase._init();
  static Database? _database;

  IngredientDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ingredients.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ingredients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        healthRating INTEGER NOT NULL,
        category TEXT NOT NULL,
        allergenRisk INTEGER,
        allergenMatch TEXT,
        commonUses TEXT,
        dietaryTags TEXT,
        healthImpact TEXT,
        warnings TEXT
      )
    ''');
  }

  Future<void> insertIngredient({
    required String name,
    required String description,
    required int healthRating,
    required String category,
    required bool allergenRisk,
    required List<String> allergenMatch,
    required List<String> commonUses,
    required List<String> dietaryTags,
    required String healthImpact,
    required String warnings,
  }) async {
    final db = await instance.database;
    await db.insert('ingredients', {
      'name': name,
      'description': description,
      'healthRating': healthRating,
      'category': category,
      'allergenRisk': allergenRisk ? 1 : 0,
      'allergenMatch': jsonEncode(allergenMatch),
      'commonUses': jsonEncode(commonUses),
      'dietaryTags': jsonEncode(dietaryTags),
      'healthImpact': healthImpact,
      'warnings': warnings,
    });
  }

  Future<List<Map<String, dynamic>>> getIngredients() async {
    final db = await instance.database;
    final result = await db.query('ingredients');
    return result.map((map) => {
      ...map,
      'allergenRisk': map['allergenRisk'] == 1,
      'allergenMatch': List<String>.from(jsonDecode(map['allergenMatch']?.toString() ?? '[]')),
      'commonUses': List<String>.from(jsonDecode(map['commonUses']?.toString() ?? '[]')),
      'dietaryTags': List<String>.from(jsonDecode(map['dietaryTags']?.toString() ?? '[]')),

    }).toList();
  }

  Future<void> deleteIngredient(int id) async {
    final db = await instance.database;
    await db.delete(
      'ingredients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}