// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:async';
import 'package:flutter/material.dart';

class ThrottledResizeWidget extends StatefulWidget {
  final Widget child;
  final void Function(Size size) onResize;

  const ThrottledResizeWidget({
    super.key,
    required this.child,
    required this.onResize,
  });

  @override
  State<ThrottledResizeWidget> createState() => _ThrottledResizeWidgetState();
}

class _ThrottledResizeWidgetState extends State<ThrottledResizeWidget> {
  Timer? _resizeTimer;
  Size? _lastSize;

  void _handleResize(Size newSize) {
    if (_lastSize == newSize) return;
    _lastSize = newSize;
    _resizeTimer?.cancel();
    _resizeTimer = Timer(const Duration(milliseconds: 200), () {
      widget.onResize(newSize);
    });
  }

  @override
  void dispose() {
    _resizeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleResize(size);
        });
        return widget.child;
      },
    );
  }
}