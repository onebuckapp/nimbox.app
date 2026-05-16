// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import './spotlight.dart';

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

Widget renderNavigationBarWithShadow(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.background.withOpacity(1),
          blurRadius: 25,
          spreadRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    ),
    child: renderNavigation(context),
  );
}


class HoverableChatbox extends StatefulWidget {
  @override
  _HoverableChatboxState createState() => _HoverableChatboxState();
}

class _HoverableChatboxState extends State<HoverableChatbox> {
  double _topPosition = -5; // Initial position
  double _tiltAngle = 0;     // Radians

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      top: _topPosition,
      right: 100,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          setState(() {
            _topPosition = -11;
            _tiltAngle = 0.12;
          });
        },
        onExit: (_) {
          setState(() {
            _topPosition = -5;
            _tiltAngle = 0;
          });
        },
        child: SizedBox(
          width: 55,
          height: 55,
          child: GestureDetector(
            onTap: () => GoRouter.of(context).go('/'),
            child: AnimatedRotation(
              turns: _tiltAngle / (2 * 3.1415926535), // Convert radians to turns
              duration: const Duration(milliseconds: 50),
              child: Image.asset(
                'assets/chatbox-1.png',
                width: 125,
                height: 125,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget renderNavigationMenu(BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width - 50,
    height: 46,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 400,
          child: NavigationMenu(
            children: [
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/'),
                child: const Text("What's new"),
              ),
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/explore'),
                child: const Text('Explore'),
              ),
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/packages'),
                child: const Text("Installed Packages"),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => showSearchPanel(context),
          child: SizedBox(
            height: 36,
            width: 430,
            child: AbsorbPointer(
              child: const TextField(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                placeholder: Text('Search in packages, docs and more...'),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 500, // Ensure enough space for the Stack
          child: Stack(
            clipBehavior: Clip.none, // Allow overflow
            children: [
              NavigationMenu(
                children: [
                  NavigationMenuItem(
                    onPressed: () => GoRouter.of(context).go('/docs'),
                    child: const Text('Documentations'),
                  ),
                  NavigationMenuItem(
                    onPressed: () => openUrl('https://forum.nim-lang.org?utm_source=nimbox&utm_medium=app&utm_campaign=navigation'),
                    child: const Text('Community'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]
    )
  );
}

Widget renderNavigation(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, right: 10, top: 32, bottom: 0),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Only the navigation bar is height-constrained
        OutlinedContainer(
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Color(0xff171921),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 90), // Reserve space for logo
                renderNavigationMenu(context),
              ],
            ),
          ),
        ),
        // Logo can overflow above the navigation bar
        Positioned(
          top: -16,
          left: 5,
          child: SizedBox(
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                GoRouter.of(context).go('/');
              },
              child: Image.asset(
                'assets/nimbox_logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        HoverableChatbox()
      ],
    ),
  );
}