/*
    Nimbox - The missing GUI for Nimble, Nim's package manager.

    Copyright (C) 2026  George Lemon from OpenPeeps

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

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
    final directory = await getApplicationSupportDirectory();
    return path.join(directory.path, 'packages.db');
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
              tags TEXT, -- JSON-encoded array of tags
              url TEXT, -- URL of the package
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

  Future<List<Map<String, dynamic>>> getSomePackages(int limit) async {
    final db = await database;
    return await db.query('packages', limit: limit);
  }

  Future<List<Map<String, dynamic>>> searchPackages(String query) async {
    final db = await database;
    final results = await db.query(
      'packages',
      where: 'name LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return results;
  }

  Future<void> clearPackages() async {
    final db = await database;
    await db.delete('packages');
  }
}