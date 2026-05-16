// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import '../../database/db_helper.dart';

void showSearchPanel(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => const _SearchPanel(),
  );
}

class _SearchPanel extends StatefulWidget {
  const _SearchPanel();

  @override
  State<_SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<_SearchPanel> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _allPackages = [];
  int _selectedIndex = -1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _controller.addListener(_onSearch);

    // Request focus when the dialog is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadPackages() async {
    final db = DBHelper();
    final packages = await db.getPackages();
    setState(() {
      _allPackages = packages;
      _results = packages.take(8).toList();
      _loading = false;
    });
  }

  void _onSearch() async {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = _allPackages.take(8).toList();
      });
      return;
    }

    final db = DBHelper();
    final searchResults = await db.searchPackages(query);

    setState(() {
      _results = searchResults;
      _selectedIndex = -1;
    });
  }

  void _selectPackage(String name) {
    Navigator.of(context).pop();
    GoRouter.of(context).go('/packages/$name');
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, _results.length - 1);
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, _results.length - 1);
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter && _selectedIndex >= 0) {
        _selectPackage(_results[_selectedIndex]['name']);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: Card(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 620,
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(TablerIcons.search, size: 20, color: Colors.white.withOpacity(0.4)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          placeholder: const Text('Search in packages, docs and more...'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlineButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      )
                    ],
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.08)),
                // Results section with fixed height
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else
                  SizedBox(
                    height: 300, // Fixed height for the results section
                    child: _results.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(TablerIcons.package_off, size: 36, color: Colors.white.withOpacity(0.2)),
                                const SizedBox(height: 10),
                                Text(
                                  'No packages found',
                                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final pkg = _results[index];
                              final isSelected = index == _selectedIndex;
                              return GestureDetector(
                                onTap: () => _selectPackage(pkg['name']),
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _selectedIndex = index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 80),
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.06),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            TablerIcons.package,
                                            size: 18,
                                            color: Colors.white.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                pkg['name'] ?? '',
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ).small,
                                              if ((pkg['description'] ?? '').isNotEmpty)
                                                Text(
                                                  pkg['description'],
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white.withOpacity(0.35),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          pkg['version'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          TablerIcons.chevron_right,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                // Footer hint
                if (_results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(TablerIcons.arrow_up, size: 12, color: Colors.white.withOpacity(0.2)),
                        Icon(TablerIcons.arrow_down, size: 12, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(width: 4),
                        Text(
                          'to navigate',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.2)),
                        ),
                        const SizedBox(width: 12),
                        Icon(TablerIcons.corner_down_left, size: 12, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(width: 4),
                        Text(
                          'to open',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      )
    );
  }
}