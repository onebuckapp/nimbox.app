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

// import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
    final panel = Container(
      // elevation: 16,
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
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        _buildPanel(context),
      ],
    );
  }
}