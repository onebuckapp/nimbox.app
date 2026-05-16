// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:flutter/material.dart';

enum PanelPosition { top, right, bottom, left, end }

class SidebarPanelController extends ChangeNotifier {
  bool _visible = false; // Default to hidden
  bool get visible => _visible; // Expose visibility state

  void show() {
    if (!_visible) {
      _visible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_visible) {
      _visible = false;
      notifyListeners();
    }
  }

  void toggle() {
    _visible = !_visible;
    notifyListeners();
  }

  bool get isOpen => _visible; // Check if the panel is open
}

class ControlledSidebarPanel extends StatefulWidget {
  final SidebarPanelController controller;
  final Widget child;
  final PanelPosition position;
  final double size; // width or height depending on position
  final bool showBackdrop;

  const ControlledSidebarPanel({
    super.key,
    required this.controller,
    required this.child,
    this.position = PanelPosition.right,
    this.size = 320,
    this.showBackdrop = true,
  });

  @override
  State<ControlledSidebarPanel> createState() => _ControlledSidebarPanelState();
}

class _ControlledSidebarPanelState extends State<ControlledSidebarPanel> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  Alignment _getAlignment(BuildContext context) {
    switch (widget.position) {
      case PanelPosition.top:
        return Alignment.topCenter;
      case PanelPosition.bottom:
        return Alignment.bottomCenter;
      case PanelPosition.left:
        return Alignment.centerLeft;
      case PanelPosition.right:
        return Alignment.centerRight;
      case PanelPosition.end:
        final isRtl = Directionality.of(context) == TextDirection.rtl;
        return isRtl ? Alignment.centerLeft : Alignment.centerRight;
    }
  }

  Widget _buildPanel(BuildContext context) {
    final media = MediaQuery.of(context);
    final isHorizontal = widget.position == PanelPosition.top || widget.position == PanelPosition.bottom;
    final panel = Material(
      elevation: 16,
      color: Colors.transparent,
      child: SizedBox(
        width: isHorizontal ? media.size.width : widget.size,
        height: isHorizontal ? widget.size : media.size.height,
        child: widget.child
      ),
    );

    return Align(
      alignment: _getAlignment(context),
      child: panel,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.visible) return const SizedBox.shrink();

    return Stack(
      children: [
        if (widget.showBackdrop)
          GestureDetector(
            onTap: widget.controller.hide,
            child: Container(
              color: Colors.white.withOpacity(0.3),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        _buildPanel(context),
      ],
    );
  }
}