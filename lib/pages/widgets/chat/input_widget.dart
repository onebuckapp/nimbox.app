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

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

const List<String> kAvailablePackages = [
  'jsony', 'libevent', 'chronicles', 'asynctools',
  'httpbeast', 'jester', 'karax', 'nimcrypto', 'regex',
  'nimble', 'zippy', 'yaml', 'toml', 'smtp',
];

class ChatInputWidget extends StatefulWidget {
  final Function(String text, List<String> packages) onSend;
  const ChatInputWidget({Key? key, required this.onSend}) : super(key: key);

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();

  // Key used to anchor the popover to the textarea
  final GlobalKey _textAreaKey = GlobalKey();

  List<String> _mentionedPackages = [];
  bool _popoverOpen = false;
  String _pkgToken = ''; // part after @pkg that the user is currently typing
  BuildContext? _popoverCtx;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _closePkgPopover() {
    if (_popoverCtx != null) {
      closeOverlay(_popoverCtx!);
      _popoverCtx = null;
    }
    setState(() {
      _popoverOpen = false;
      _pkgToken = '';
    });
    _textFocus.requestFocus(); // 👈 return focus to textarea
  }

  void _onTextChanged() {
    final text = _textController.text;
    final pkgMatch = RegExp(r'@pkg\s+(\S*)$').firstMatch(text);

    if (pkgMatch != null) {
      final token = pkgMatch.group(1) ?? '';
      _pkgToken = token;
      if (!_popoverOpen) _openPkgPopover();
    } else {
      if (_popoverOpen) _closePkgPopover();
    }
  }

  void _openPkgPopover() {
    _popoverOpen = true;
    final ctx = _textAreaKey.currentContext;
    if (ctx == null) return;

    showPopover(
      context: ctx,
      alignment: Alignment.topCenter,
      offset: const Offset(0, 10),
      builder: (popoverContext) {
        _popoverCtx = popoverContext; // 👈 capture it here
        return _PkgSuggestionsPopover(
          tokenStream: _textController,
          packages: kAvailablePackages,
          alreadyMentioned: _mentionedPackages,
          onSelect: (pkg) {
            final updated = _textController.text
                .replaceAll(RegExp(r'@pkg\s+\S*$'), '')
                .replaceAll(RegExp(r'@pkg\s*$'), '');
            setState(() {
              _mentionedPackages = [..._mentionedPackages, pkg];
            });
            _textController
              ..text = updated
              ..selection = TextSelection.collapsed(offset: updated.length);
            _closePkgPopover();
          },
          onDismiss: _closePkgPopover,
        );
      },
    ).future.then((_) {
      _popoverOpen = false;
      _popoverCtx = null;
    });
  }

  void _removePackage(String pkg) {
    setState(() => _mentionedPackages = _mentionedPackages.where((p) => p != pkg).toList());
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty && _mentionedPackages.isEmpty) return;
    widget.onSend(text, List.from(_mentionedPackages));
    _textController.clear();
    setState(() => _mentionedPackages = []);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            _popoverOpen) {
          // Clear @pkg from text — _onTextChanged will call _closePkgPopover
          final cleaned = _textController.text
              .replaceAll(RegExp(r'@pkg\s+\S*$'), '')
              .replaceAll(RegExp(r'@pkg\s*$'), '');
          _textController.text = cleaned;
          _textController.selection =
              TextSelection.collapsed(offset: cleaned.length);
          _closePkgPopover();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mentioned packages chips row
          if (_mentionedPackages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text('Packages:').muted.small,
                  ..._mentionedPackages.map((pkg) => Chip(
                    trailing: ChipButton(
                      onPressed: () => _removePackage(pkg),
                      child: const Icon(Icons.close, size: 12),
                    ),
                    child: Text(pkg).small,
                  )),
                ],
              ),
            ),

          // Single always-visible TextArea — anchored for popover
          SizedBox(
            key: _textAreaKey,
            child: TextArea(
              borderRadius: BorderRadius.circular(14),
              controller: _textController,
              focusNode: _textFocus,
              placeholder: const Text('Type a message…'),
              minLines: 2,
              maxLines: 5,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PrimaryButton(
                onPressed: _handleSend,
                child: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


//
// Popover content — stateful so it can react to token changes live
//
class _PkgSuggestionsPopover extends StatefulWidget {
  final TextEditingController tokenStream;
  final List<String> packages;
  final List<String> alreadyMentioned;
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  const _PkgSuggestionsPopover({
    required this.tokenStream,
    required this.packages,
    required this.alreadyMentioned,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<_PkgSuggestionsPopover> createState() => _PkgSuggestionsPopoverState();
}

class _PkgSuggestionsPopoverState extends State<_PkgSuggestionsPopover> {
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    widget.tokenStream.addListener(_updateFilter);
    _updateFilter();
  }

  void _updateFilter() {
    final text = widget.tokenStream.text;
    final match = RegExp(r'@pkg\s+(\S*)$').firstMatch(text);
    final token = match?.group(1) ?? '';
    setState(() {
      _filtered = widget.packages
          .where((p) =>
              (token.isEmpty || p.startsWith(token)) &&
              !widget.alreadyMentioned.contains(p))
          .toList();
    });
  }

  @override
  void dispose() {
    widget.tokenStream.removeListener(_updateFilter);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalContainer(
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PrimaryBadge(child: const Text('@pkg').small),
                const SizedBox(width: 8),
                Text('Select a package').muted.small,
              ],
            ),
            const SizedBox(height: 8),
            if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text('No packages found').muted.small,
                ),
              )
            else
              SizedBox(
                height: 200, // Set a fixed height for the scrollable area
                child: SingleChildScrollView(
                  child: Column(
                    children: _filtered.map((pkg) {
                      return Clickable(
                        onPressed: () => widget.onSelect(pkg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(TablerIcons.box, size: 16, color: Colors.slate),
                              const SizedBox(width: 8),
                              Text(pkg).small,
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}