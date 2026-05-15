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

  @override
  void initState() {
    super.initState();
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
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'Custom',
          menus: [
            // Add the default About menu item
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
            PlatformMenuItem(
              label: 'New Document',
              onSelected: () {
                debugPrint('New Document selected');
                // Your logic here
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
                shift: true,
              ),
            ),
            PlatformMenuItem(
              label: 'Preferences...',
              onSelected: () {
                debugPrint('Preferences selected');
                // Your logic here
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                meta: true,
              ),
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Tool 1',
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.digit1,
                    meta: true,
                    alt: true,
                  ),
                ),
                PlatformMenuItem(
                  label: 'Tool 2',
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.digit2,
                    meta: true,
                    alt: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      // child: Scaffold(
      //   child: Stack(
      //     children: [
      //       Padding(
      //         padding: const EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 0),
      //         child: SingleChildScrollView(
      //           child: Padding(
      //             padding: const EdgeInsets.only(top: 130, left: 20, right: 20),
      //             child: Column(
      //               crossAxisAlignment: CrossAxisAlignment.start,
      //               children: [
      //                 Row(
      //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //                   mainAxisSize: MainAxisSize.max,
      //                   children: [
      //                     SizedBox(
      //                       height: 280,
      //                       child: Card(
      //                         padding: const EdgeInsets.all(0),
      //                         borderRadius: BorderRadius.circular(15),
      //                         clipBehavior: Clip.antiAlias,
      //                         child: Container(
      //                           width: 280,
      //                           decoration: BoxDecoration(
      //                             image: DecorationImage(
      //                               image: NetworkImage('https://plus.unsplash.com/premium_photo-1754433115781-a0f536b10258?q=80&w=1025&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
      //                               fit: BoxFit.cover,
      //                             ),
      //                           ),
      //                           child: Container(
      //                             padding: const EdgeInsets.all(24),
      //                             decoration: BoxDecoration(
      //                               gradient: LinearGradient(
      //                                 begin: Alignment.bottomCenter,
      //                                 end: Alignment.topCenter,
      //                                 colors: [
      //                                   Colors.black.withOpacity(0.7),
      //                                   Colors.transparent,
      //                                 ],
      //                               ),
      //                             ),
      //                             child: Align(
      //                               alignment: Alignment.bottomLeft,
      //                               child: Column(
      //                                 mainAxisSize: MainAxisSize.min,
      //                                 crossAxisAlignment: CrossAxisAlignment.start,
      //                                 children: [
      //                                   SecondaryBadge(
      //                                     child: const Text("2.2.4").semiBold.small,
      //                                   ),
      //                                   const SizedBox(height: 8),
      //                                   Text("Update Available").medium.h1,
      //                                   Text(
      //                                     "A new update is now available. This update includes new features, bug fixes, and performance improvements.",
      //                                     maxLines: 3,
      //                                     overflow: TextOverflow.ellipsis,
      //                                   ).light.p,
      //                                 ],
      //                               ),
      //                             ),
      //                           ),
      //                         ),
      //                       )
      //                     ),
      //                   ],
      //                 ),
      //               ],
      //             ),
      //           )
      //         )
      //       ),
      //       renderNavigationBarWithShadow(context),
      //     ]
      //   )
      // )
      child: Scaffold(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 126),
                  // const Text(
                  //   "Available Packages",
                  //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  // ),
                  // const SizedBox(height: 16),
                  Expanded(
                    child: _packages.isEmpty
                      ? const Center(child: Text("Loading packages..."))
                      : SingleChildScrollView(
                          child: Container(
                            width: double.infinity, // Ensures the scroll view fits the app width
                            padding: EdgeInsets.only(top: 20, bottom: 20),
                            margin: EdgeInsets.only(top: 80),
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
                ],
              ),
            ),
            renderNavigationBarWithShadow(context),
          ],
        ),
      )
    );
  }
}