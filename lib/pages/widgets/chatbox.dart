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

import './chatview.dart';
import './chat/input_widget.dart';

class ChatboxWidget extends StatefulWidget {
  const ChatboxWidget({Key? key}) : super(key: key);

  @override
  State<ChatboxWidget> createState() => _ChatboxWidgetState();
}

class _ChatboxWidgetState extends State<ChatboxWidget> {
  final ChatViewController _chatController = ChatViewController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
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
                      label: const Text('Conversations').small.muted.light,
                      children: [],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ChatView(controller: _chatController),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ChatInputWidget(onSend: (text, packages) => _chatController.sendMessage(text, packages)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function for building navigation buttons
Key? selected = const ValueKey(0);

Widget newNavItem(int key, String label, [IconData? icon]) {
  return NavigationItem(
    key: ValueKey(key),
    label: Text(label),
    child: icon != null ? Icon(icon) : const SizedBox.shrink(), // Provide a default non-null Widget
  );
}