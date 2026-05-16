// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

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
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _packages.isEmpty
                    ? const Center(child: Text("Loading packages..."))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final contentWidth = constraints.maxWidth < _minContentWidth
                              ? _minContentWidth
                              : constraints.maxWidth;
                          return Scrollbar(
                            controller: _horizontalScrollController,
                            thumbVisibility: constraints.maxWidth < _minContentWidth,
                            child: SingleChildScrollView(
                              controller: _horizontalScrollController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: contentWidth,
                                child: Scrollbar(
                                  controller: _verticalScrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _verticalScrollController,
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                                      margin: const EdgeInsets.only(top: 80),
                                      child: Wrap(
                                        spacing: 14,
                                        runSpacing: 14,
                                        children: _packages.map((package) {
                                          return PackageCard(
                                            title: package['name'],
                                            desc: package['description'],
                                            author: package['author'],
                                            version: package['version'],
                                            license: package['license'],
                                            width: 255,
                                            height: 130,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          renderNavigationBarWithShadow(context),
        ],
      ),
    );
  }

}