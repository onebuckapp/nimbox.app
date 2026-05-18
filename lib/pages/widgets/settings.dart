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

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Row(
        children: [
          // Sidebar
          Expanded(
            flex: 1,
            child: SizedBox(
              height: double.infinity,
              child: OutlinedContainer(
                borderRadius: BorderRadius.circular(0),
                child: NavigationSidebar(
                  selectedKey: selected,
                  onSelected: (key) {
                    // Update the selected key
                    selected = key;
                  },
                  children: [
                    NavigationGroup(
                      label: const Text('General Settings').small.muted.light,
                      children: [
                        buildButton('Listen Now', BootstrapIcons.playCircle,
                            const ValueKey(0)),
                        buildButton('Browse', BootstrapIcons.grid,
                            const ValueKey(1)),
                        buildButton('Radio', BootstrapIcons.broadcast,
                            const ValueKey(2)),
                      ],
                    ),
                    const NavigationGap(24),
                    const NavigationDivider(),
                    NavigationGroup(
                      label: const Text('Chatbox').small.muted.light,
                      children: [
                        buildButton('LLM Providers', 
                          TablerIcons.ai,
                            const ValueKey(3)),
                        buildButton('Conversations', TablerIcons.message,
                            const ValueKey(4)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main content area
          Expanded(
            flex: 3,
            child: Center(
              child: const Text(
                'Select an option from the sidebar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function for building navigation buttons
Key? selected = const ValueKey(0);

Widget buildButton(String label, IconData icon, Key key) {
  return NavigationItem(
    key: key,
    label: Text(label),
    child: Icon(icon),
  );
}