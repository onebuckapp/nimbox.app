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

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.isDark,
  });

  final String title;
  final bool isDark;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
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

  Widget renderPackageCard({
    required String title,
    required String desc,
    required String author,
    required String version,
    required String license,
    required List<MenuButton> contextMenuItems,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    double borderRadius = 12,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return ContextMenu(
          items: contextMenuItems,
          child: ButtonStyleOverride(
            padding: (context, states, value) => const EdgeInsets.all(0),
            child: TextButton(
              onPressed: () {
                GoRouter.of(context).go('/packages/$title');
              },
              child: Card(
                borderRadius: BorderRadius.circular(borderRadius),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Container(
                    padding: padding ?? const EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title).medium.h4,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('by ${author}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.slate)
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).light.small,
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            new Icon(TablerIcons.tag, size: 16, color: Colors.slate),
                            const SizedBox(width: 3),
                            Text('${version}').light.small,
                            const SizedBox(width: 10),
                            new Icon(TablerIcons.license, size: 16, color: Colors.slate),
                            const SizedBox(width: 3),
                            Text('${license}').light.small,
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
                                          return renderPackageCard(
                                            title: package['name'] ?? 'Unknown Package',
                                            desc: package['description'] ?? 'No description available.',
                                            author: package['author'] ?? 'Unknown Author',
                                            version: package['version'] ?? 'N/A',
                                            license: package['license'] ?? 'Unknown',
                                            contextMenuItems: [
                                              MenuButton(
                                                child: const Text('View Details'),
                                                onPressed: (context) {
                                                  GoRouter.of(context).go('/packages/${package['name']}');
                                                },
                                              ),
                                              MenuButton(
                                                child: const Text('Delete'),
                                                onPressed: (context) async {
                                                  final dbHelper = DBHelper();
                                                  await dbHelper.clearPackages();
                                                  _loadPackages();
                                                },
                                              ),
                                            ],
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