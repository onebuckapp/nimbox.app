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
import '../utils/util.dart';

import './partials/navigation.dart';
import './partials/feedcard_updates.dart';
import './partials/feedcard_forum.dart';

import './widgets/package_card.dart';
import './widgets/panel.dart';

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
    final packages = await dbHelper.getSomePackages(10);
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
            child: SingleChildScrollView( // Wrap the entire content in a SingleChildScrollView
              controller: _verticalScrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        height: 300,
                        child: FeedCardUpdates(),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        height: 300,
                        child: FeedCardForum(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 300,
                          child: Card(
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.all(0),
                            child: Container(
                              width: 620,
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(children: [
                                      Icon(TablerIcons.book, size: 20, color: Colors.slate),
                                      const SizedBox(width: 6),
                                      const Text('Offline docs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ]),
                                  ),
                                  Expanded(child: 
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text('Coming Soon...').small.muted.light,
                                    )
                                  ),
                                ],
                              ),
                            ),
                          )
                        )
                      )
                    ],
                  ),
                  const SizedBox(height: 20), // Add spacing between sections
                  _packages.isEmpty
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Local packages').medium.h3,
                                        const SizedBox(width: 24),
                                        OutlineButton(
                                          child: const Text('See all packages'),
                                          onPressed: () {
                                            GoRouter.of(context).go('/packages');
                                          },
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: contentWidth,
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
                                  ],
                                )
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          renderNavigationBarWithShadow(context),
        ],
      ),
    );
  }

}