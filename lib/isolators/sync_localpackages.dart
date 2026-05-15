// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:isolate';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../database/db_helper.dart';

class SyncLocalPackages {
  final void Function(String output)? onSuccess;
  final void Function(String pkgName)? onSync;
  final StreamController<String> _syncStreamController = StreamController<String>.broadcast();

  SyncLocalPackages({this.onSuccess, this.onSync});
  Stream<String> get syncStream => _syncStreamController.stream;

  Future<void> syncPackages() async {
    final dbPath = await DBHelper.getDatabasePath();
    final receivePort = ReceivePort();
    print('Starting sync with database at: $dbPath');
    
    // Spawn the isolate and pass the SendPort and database path
    await Isolate.spawn(_localPackagesIsolateEntry, [receivePort.sendPort, dbPath]);
    
    // Listen for messages from the isolate
    receivePort.listen((message) {
      if (message is Map && message['pkg'] != null) {
        _syncStreamController.add(message['pkg'] as String); // Emit package name to stream
        if (onSync != null) onSync!(message['pkg'] as String);
      } else if (message is Map && message['status'] == 'done') {
        if (onSuccess != null) onSuccess!('Sync completed');
        _syncStreamController.close(); // Close the stream when done
        receivePort.close();
      } else if (message is Map && message['error'] != null) {
        print('Sync error: ${message['error']}');
        _syncStreamController.close(); // Close the stream on error
        receivePort.close();
      }
    });
  }
  static Future<void> _localPackagesIsolateEntry(List<dynamic> args) async {
    final sendPort = args[0] as SendPort;
    final dbPath = args[1] as String;

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Open a fresh database connection inside the isolate
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
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
      ),
    );

    try {
      // await db.delete('packages');

      final result = await Process.run('nimble', ['list', '--installed']);
      if (result.exitCode != 0) {
        sendPort.send({'error': 'nimble list failed: ${result.stderr}'});
        return;
      }

      final lines = (result.stdout as String).split('\n');
      final pkgNames = lines
          .map((line) => line.split(' ').first.trim())
          .where((name) => name.isNotEmpty)
          .toList();

      // Run all nimble dump commands concurrently
      const concurrencyLimit = 10;
      final packages = <Map<String, dynamic>>[];

      for (var i = 0; i < pkgNames.length; i += concurrencyLimit) {
        final chunk = pkgNames.sublist(i, (i + concurrencyLimit).clamp(0, pkgNames.length));
        final chunkFutures = chunk.map((pkgName) async {
          final dumpResult = await Process.run('nimble', ['dump', pkgName, '--json']);
          if (dumpResult.exitCode != 0) return null;
          try {
            final dumpData = jsonDecode(dumpResult.stdout as String) as Map<String, dynamic>;
            sendPort.send({'pkg': pkgName});
            return {
              'name': dumpData['name'] ?? pkgName,
              'version': dumpData['version'] ?? 'unknown',
              'description': dumpData['desc'] ?? '',
              'author': dumpData['author'] ?? '',
              'license': dumpData['license'] ?? '',
              'nimble_path': dumpData['nimblePath'] ?? '',
            };
          } catch (e) {
            print('Failed to parse $pkgName: $e');
            return null;
          }
        });

        final chunkResults = await Future.wait(chunkFutures);
        packages.addAll(chunkResults.whereType<Map<String, dynamic>>());
      }

      // Bulk insert in a single transaction
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final pkg in packages) {
          batch.insert('packages', pkg, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });

      sendPort.send({'status': 'done'});
      
    } catch (e) {
      sendPort.send({'error': e.toString()});
    } finally {
      await db.close();
    }
  }
}