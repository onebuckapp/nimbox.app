// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<String> getDatabasePath() async {
    final dbPath = await databaseFactoryFfi.getDatabasesPath();
    return join(dbPath, 'packages.db');
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasePath();
    print('Database path: $path');
    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS packages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              version TEXT NOT NULL,
              description TEXT,
              author TEXT,
              license TEXT,
              nimble_path TEXT,
              UNIQUE(name, version)
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // Handle database upgrades if needed in the future
        },
      ),
    );
  }

  Future<void> insertPackage(Map<String, dynamic> package) async {
    final db = await database;
    await db.insert(
      'packages',
      package,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPackages() async {
    final db = await database;
    return await db.query('packages');
  }

  Future<void> clearPackages() async {
    final db = await database;
    await db.delete('packages');
  }
}