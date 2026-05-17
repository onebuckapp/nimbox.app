// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import './resizer.dart';

class WebView extends StatefulWidget {
  final String initialUrl;
  final VoidCallback? onClose;
  const WebView({super.key, required this.initialUrl, this.onClose});

  @override
  State<WebView> createState() => _WebViewState();
}

class _WebViewState extends State<WebView> {
  static const MethodChannel _channel = MethodChannel('custom_webview_context_menu');

  double _editorWidth = 600; // initial width, adjust as needed
  bool _resizing = false;

  @override
  void initState() {
    super.initState();
    MethodChannel('custom_webview_context_menu').setMethodCallHandler((call) async {
      print('Received method call: ${call.method}');
      if (call.method == 'unfocusTextFields') {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'getContextMenuItems') {
        // Nested menu example
        return [
          {'title': 'Copilot', 'actionId': 'action1'},
          {
            'title': 'More Actions',
            'children': [
              {'title': 'Sub Action 1', 'actionId': 'sub1'},
              {'title': 'Sub Action 2', 'actionId': 'sub2'},
            ]
          },
          {'title': 'Custom Action 2', 'actionId': 'action2'},
          {'title': 'Inspect Element', 'actionId': 'inspect'},
        ];
      } else if (call.method == 'onMenuItemSelected') {
        final actionId = call.arguments['actionId'];
        // Handle the action in Dart
        if (actionId == 'action1') {
          // Do something for action 1
        } else if (actionId == 'action2') {
          // Do something for action 2
        } else if (actionId == 'sub1') {
          // Do something for sub action 1
        } else if (actionId == 'sub2') {
          // Do something for sub action 2
        }
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // future: loadHtmlFromAssets(),
      future: Future.value(widget.initialUrl), // Use the initial URL directly
      builder: (context, snapshot) {
        return ThrottledResizeWidget(
          onResize: (size) {
            // You can trigger a rebuild, update state, or send the new size to your native view here.
            // For example, setState(() => _webViewSize = size);
          },
          child: RepaintBoundary(
            child: AppKitView(
              viewType: 'macos_webview',
              layoutDirection: TextDirection.ltr,
              creationParams: {
                'url': widget.initialUrl,
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
          )
        );
      },
    );
  }
}