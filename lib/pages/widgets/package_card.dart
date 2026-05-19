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

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../main.dart';
import '../../utils/util.dart';
import '../../database/db_helper.dart';

import './wkwebview.dart';

// ...existing code...

class PackageCard extends StatefulWidget {
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
  _PackageCardState createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Define default menu items
    final appRootState = context.findAncestorStateOfType<AppRootState>();
    final defaultMenuItems = [
      MenuButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('View package'),
                const SizedBox(width: 4),
                Icon(TablerIcons.box, size: 14, color: Colors.slate),
              ]
            ),
            Text('Open package details page',
              style: TextStyle(fontSize: 12, color: Colors.slate)).light,
          ],
        ),
        onPressed: (context) {
          GoRouter.of(context).go('/packages/${widget.title}');
        },
      ),
      MenuButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('View documentation'),
                const SizedBox(width: 4),
                Icon(TablerIcons.book, size: 14, color: Colors.slate),
              ]
            ),
            Text('Open local documentation',
              style: TextStyle(fontSize: 12, color: Colors.slate)).light,
          ],
        ),
        onPressed: (context) {
          GoRouter.of(context).go('/packages/${widget.title}/docs');
        },
      ),
      MenuButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Open in Chatbox'),
                const SizedBox(width: 4),
                Icon(TablerIcons.external_link, size: 14, color: Colors.slate),
              ]
            ),
            Text('Start a conversation about this',
              style: TextStyle(fontSize: 12, color: Colors.slate)).light,
          ],
        ),
        onPressed: (context) {
          final repoUrl = 'https://google.com';
          appRootState?.openWebView(repoUrl); // Open the webview panel
        },
      ),
      MenuButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Open repository'),
                const SizedBox(width: 4),
                Icon(TablerIcons.external_link, size: 14, color: Colors.slate),
              ]
            ),
            Text('Open package repository in browser',
              style: TextStyle(fontSize: 12, color: Colors.slate)).light,
          ],
        ),
        onPressed: (context) {
          final repoUrl = 'https://google.com';
          appRootState?.openWebView(repoUrl); // Open the webview panel
        },
      ),
      MenuButton(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uninstall package'),
            Text('Try execute nimble uninstall <pkg>', style: TextStyle(fontSize: 12, color: Colors.slate)).light,
          ],
        ),
        onPressed: (context) async {
          final dbHelper = DBHelper();
          print('Deleted package: ${widget.title}');
        },
      ),
    ];

    // Merge default menu items with provided ones
    final mergedMenuItems = [
      ...defaultMenuItems,
      if (widget.contextMenuItems != null) ...widget.contextMenuItems!,
    ];

    return ContextMenu(
      items: mergedMenuItems,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 30),
          curve: Curves.easeInOut,
          child: ButtonStyleOverride(
            padding: (context, states, value) => const EdgeInsets.all(0),
            child: TextButton(
              onPressed: () {
                GoRouter.of(context).go('/packages/${widget.title}');
              },
              child: Card(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(10),
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title).medium.h4,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'by ${widget.author}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.slate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).light.small,
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(TablerIcons.tag, size: 16, color: Colors.slate),
                            const SizedBox(width: 3),
                            Text(widget.version).light.small,
                            const SizedBox(width: 10),
                            Icon(TablerIcons.license, size: 16, color: Colors.slate),
                            const SizedBox(width: 3),
                            Text(widget.license).light.small,
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}