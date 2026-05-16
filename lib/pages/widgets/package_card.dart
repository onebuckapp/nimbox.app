// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../main.dart';
import '../../utils/util.dart';
import '../../database/db_helper.dart';

import './wkwebview.dart';

class PackageCard extends StatelessWidget {
  final String title;
  final String desc;
  final String author;
  final String version;
  final String license;
  final List<MenuButton>? contextMenuItems;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const PackageCard({
    Key? key,
    required this.title,
    required this.desc,
    required this.author,
    required this.version,
    required this.license,
    this.contextMenuItems,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define default menu items
    final appRootState = context.findAncestorStateOfType<AppRootState>();
    final defaultMenuItems = [
      MenuButton(
        child: const Text('View package'),
        onPressed: (context) {
          GoRouter.of(context).go('/packages/$title');
        },
      ),
      MenuButton(
        child: const Text('Open documentation'),
        onPressed: (context) {
          GoRouter.of(context).go('/packages/$title/docs');
        },
      ),
      // MenuButton(
      //   child: const Text('Open repository'),
      //   onPressed: (context) {
      //     print('Opening repository for $title');
      //     openUrl('https://github.com/$author/$title');
      //   },
      // ),
      MenuButton(
        child: const Text('Open repository'),
        onPressed: (context) {
          final repoUrl = 'https://google.com';
          appRootState?.openWebView(repoUrl); // Open the webview panel
        },
      ),
      MenuButton(
        child: const Text('Delete'),
        onPressed: (context) async {
          final dbHelper = DBHelper();
          await dbHelper.clearPackages();
          print('Deleted package: $title');
        },
      ),
    ];

    // Merge default menu items with provided ones
    final mergedMenuItems = [
      ...defaultMenuItems,
      if (contextMenuItems != null) ...contextMenuItems!,
    ];

    return ContextMenu(
      items: mergedMenuItems, // Use the merged menu items directly
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
                        Text(
                          'by $author',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.slate),
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
                        Icon(TablerIcons.tag, size: 16, color: Colors.slate),
                        const SizedBox(width: 3),
                        Text(version).light.small,
                        const SizedBox(width: 10),
                        Icon(TablerIcons.license, size: 16, color: Colors.slate),
                        const SizedBox(width: 3),
                        Text(license).light.small,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}