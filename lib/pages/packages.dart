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

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../isolators/sync_localpackages.dart';
import '../database/db_helper.dart';
import '../dialogs/syncing_dialog.dart';
import '../services/notification_service.dart';

import './partials/navigation.dart';
import './widgets/package_card.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({
    super.key,
    required this.title,
    required this.isDark,
  });

  final String title;
  final bool isDark;

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> with WidgetsBindingObserver {
  late SyncLocalPackages _syncLocalPackages;
  List<Map<String, dynamic>> _packages = [];
  bool _isSyncing = false;


  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;

  // 4 cards * width + 3 gaps + horizontal padding
  static const double _minContentWidth = 4 * 255.0 + 3 * 14.0 + 40.0;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final dbPath = await DBHelper.getDatabasePath();
      if (!File(dbPath).existsSync()) {
        _syncPackages();
      } else {
        _loadPackages();
      }
    });
  }

  Future<void> _loadPackages() async {
    final dbHelper = DBHelper();
    final packages = await dbHelper.getPackages();
    setState(() {
      _packages = packages;
    });
  }

  Future<void> _syncPackages() async {
    // Show dialog before sync starts
    _syncLocalPackages = SyncLocalPackages(
      onSuccess: (_) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        NotificationService.show(id: 1, title: 'Hello', body: 'This is a notification!');

        _loadPackages();
        setState(() {
          _isSyncing = false;
        });
      },
    );
    
    // Show dialog with syncStream
    showSyncingDialog(context, _syncLocalPackages.syncStream);

    try {
      await _syncLocalPackages.syncPackages();
    } catch (e) {
      print('Sync failed: $e');
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _packages.isEmpty
                    ? const Center(child: Text("Loading packages..."))
                    : Scrollbar(
                        controller: _verticalScrollController,
                        thumbVisibility: true,
                        child: GridView.builder(
                          controller: _verticalScrollController,
                          padding: const EdgeInsets.only(top: 20, bottom: 20, left: 20, right: 20),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 290,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 140
                          ),
                          itemCount: _packages.length,
                          itemBuilder: (context, index) {
                            final package = _packages[index];
                            return PackageCard(
                              title: package['name'],
                              desc: package['description'],
                              author: package['author'],
                              version: package['version'],
                              license: package['license'],
                              width: 290,
                              height: 140
                            );
                          },
                        ),
                      ),
                )
              ],
            ),
          ),
          renderNavigationBarWithShadow(context),
        ],
      ),
    );
  }

}