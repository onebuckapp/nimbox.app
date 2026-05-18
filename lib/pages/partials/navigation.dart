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
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import './spotlight.dart';
import '../../main.dart';
import '../../utils/util.dart';

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
  // Timer? _timer; // periodic checks the health of the Chatbox
  
  @override
  void initState() {
    super.initState();
    // Start a periodic timer to check chatboxEnabled every 5 minutes
    // _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
    //   setState(() {
    //     print('Checking chatboxEnabled: ${context.findAncestorStateOfType<AppRootState>()?.chatboxEnabled}'); // Debugging
    //   }); // trigger a rebuild to reflect the latest state
    // });
  }

  @override
  void dispose() {
    // _timer?.cancel(); // cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appRootState = context.findAncestorStateOfType<AppRootState>();
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      top: _topPosition,
      right: 10,
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
            _topPosition = -2;
            _tiltAngle = 0;
          });
        },
        child: SizedBox(
          width: 55,
          height: 55,
          child: GestureDetector(
            // onTap: () =>  appRootState?.openSettingsPanel(),
            onTap: () =>  appRootState?.openChatPanel(),
            child: AnimatedRotation(
              turns: _tiltAngle / (2 * 3.1415926535), // Convert radians to turns
              duration: const Duration(milliseconds: 50),
              child: Image.asset(
                (
                  appRootState?.chatboxEnabled ?? false
                  ? 'assets/chatbox-1.png'
                  : 'assets/chatbox-2.png'
                ),
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 550,
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
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/docs'),
                child: const Text('Documentations'),
              ),
              NavigationMenuItem(
                onPressed: () => openUrl('https://forum.nim-lang.org?utm_source=nimbox&utm_medium=app&utm_campaign=navigation'),
                child: Row(
                  children: [
                    const Text('Forum'),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.externalLink, size: 12, color: Colors.slate),
                  ],
                )
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          width: 320,
          child: GestureDetector(
            onTap: () => showSearchPanel(context),
            child: AbsorbPointer(
              child: const TextField(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                placeholder: Text('Search in packages, docs and more...'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 150,
          child: NavigationMenu(
            children: [
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/'),
                child: const Text("Settings"),
              ),
            ]
          )
        )
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