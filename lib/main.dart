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
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './services/notification_service.dart';

import './pages/home.dart';
import './pages/packages.dart';
import './pages/package.dart';

import './pages/widgets/wkwebview.dart';
import './pages/widgets/panel.dart';
import './pages/widgets/settings.dart';
import './pages/widgets/chatbox.dart';

class AppRoot extends StatefulWidget {
  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  // Move the _router variable here
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MyHomePage(
          title: "What's new",
          isDark: true,
        ),
      ),
      GoRoute(
        path: '/packages',
        builder: (context, state) => PackagesPage(
          title: 'Packages',
          isDark: true,
        ),
      ),
      GoRoute(
        path: '/packages/:title',
        builder: (context, state) => PackagePage(
          title: state.pathParameters['title']!,
          isDark: true,
        ),
      ),
    ],
  );

  double sidebarWidth = 200;

  final SidebarPanelController _panelController = SidebarPanelController();
  final SidebarPanelController _chatPanelController = SidebarPanelController();
  final SidebarPanelController _settingsPanelController = SidebarPanelController();
  String? _webViewUrl; // Store the current URL for the webview
  bool chatboxEnabled = false; // Track whether the chatbox is enabled

  void openWebView(String url) {
    print('Opening WebView with URL: $url'); // Debugging
    setState(() {
      _webViewUrl = url;
      _panelController.show(); // Show the panel
    });
  }

  void openChatPanel() {
    _chatPanelController.show();
  }

  void openSettingsPanel() {
    _settingsPanelController.show();
  }

  final ThemeData _appTheme = ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      background: Color(0xff0f1116),
      foreground: Color(0xfffafafa),
      card: Color(0xff171921),
      cardForeground: Color(0xfffafafa),
      popover: Color(0xff171921),
      popoverForeground: Color(0xfffafafa),
      primary: Color(0xfff99c19),
      primaryForeground: Color(0xfff5f3ff),
      secondary: Color(0xff27272a),
      secondaryForeground: Color(0xfffafafa),
      muted: Color(0xff27272a),
      mutedForeground: Color(0xff9f9fa9),
      accent: Color(0xff27272a),
      accentForeground: Color(0xfffafafa),
      destructive: Color(0xffff6467),
      destructiveForeground: Color(0x0),
      border: Color(0x1affffff),
      input: Color(0x26ffffff),
      ring: Color(0xff7f22fe),
      chart1: Color(0xff1447e6),
      chart2: Color(0xff00bc7d),
      chart3: Color(0xfffe9a00),
      chart4: Color(0xffad46ff),
      chart5: Color(0xffff2056),
    ),
    density: Density.reducedDensity,
    surfaceOpacity: 0.8,
    surfaceBlur: 8,
    radius: 0.7,
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          ShadcnApp.router(
            title: 'Nimbox',
            debugShowCheckedModeBanner: false,
            routerConfig: _router, // Use the _router variable here
            theme: _appTheme,
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (overlayContext) => Stack(
                          children: [
                              Builder(
                                builder: (context) => IgnorePointer(
                                  child: OverflowBox(
                                    alignment: Alignment.topLeft,
                                    minWidth: 0,
                                    minHeight: 0,
                                    maxWidth: double.infinity,
                                    maxHeight: double.infinity,
                                    child: Transform.scale(
                                      scale: 0.5,
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        width: MediaQuery.of(context).size.width / 0.5,
                                        height: MediaQuery.of(context).size.height / 0.5,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/noise.png'),
                                            repeat: ImageRepeat.repeat,
                                            opacity: 0.28,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              ControlledSidebarPanel(
                                controller: _panelController,
                                position: PanelPosition.bottom,
                                size: 750,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32), // Adjust as needed
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF211b1f),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      border: Border(
                                        top: BorderSide(color: Colors.stone[800], width: 6),
                                        left: BorderSide(color: Colors.stone[800], width: 6),
                                        right: BorderSide(color: Colors.stone[800], width: 6),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25), // Shadow color
                                          blurRadius: 32, // Spread of the shadow
                                          offset: Offset(0, -8), // Horizontal & vertical offset
                                          spreadRadius: 2, // Optional: how much the shadow spreads
                                        ),
                                      ],
                                    ),
                                    width: sidebarWidth,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: SizedBox.expand(
                                        child: _webViewUrl != null
                                          ? WebView(
                                              initialUrl: _webViewUrl!,
                                              onClose: () => _panelController.hide(),
                                            )
                                          : const SizedBox.shrink(),
                                      ),
                                    ),
                                  )
                                ),
                              ),
                              ControlledSidebarPanel(
                                controller: _settingsPanelController,
                                position: PanelPosition.right,
                                size: 720,
                                child: Theme(
                                  data: _appTheme,
                                  child: SettingsPage(),
                                ),
                              ),
                              ControlledSidebarPanel(
                                controller: _chatPanelController,
                                position: PanelPosition.right,
                                size: 720,
                                child: Theme(
                                  data: _appTheme,
                                  child: Container(
                                    color: const Color(0xFF111116),
                                    child: chatboxEnabled
                                      ? WebView(initialUrl: 'http://127.0.0.1:8000', onClose: () => _chatPanelController.hide())
                                      : Stack(
                                        children: [
                                          // ChatSettings(
                                          //   onCancel: () {
                                          //     // Handle cancel action
                                          //   },
                                          //   onDeploy: () {
                                          //     // Handle deploy action
                                          //   },
                                          // ),
                                          ChatboxWidget(),
                                          Builder(
                                            builder: (context) => IgnorePointer(
                                              child: OverflowBox(
                                                alignment: Alignment.topLeft,
                                                minWidth: 0,
                                                minHeight: 0,
                                                maxWidth: double.infinity,
                                                maxHeight: double.infinity,
                                                child: Transform.scale(
                                                  scale: 0.5,
                                                  alignment: Alignment.topLeft,
                                                  child: Container(
                                                    width: MediaQuery.of(context).size.width / 0.5,
                                                    height: MediaQuery.of(context).size.height / 0.5,
                                                    decoration: const BoxDecoration(
                                                      image: DecorationImage(
                                                        image: AssetImage('assets/noise.png'),
                                                        repeat: ImageRepeat.repeat,
                                                        opacity: 0.28,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                ),
                              ),
                          ]
                        )
                      )
                    ]
                  ),
                ]
              );
            }
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  runApp(ProviderScope(child: AppRoot()));
}

