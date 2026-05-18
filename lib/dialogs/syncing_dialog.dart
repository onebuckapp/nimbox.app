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
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> showSyncingDialog(BuildContext context, Stream<String> syncStream) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StreamBuilder<String>(
        stream: syncStream,
        builder: (context, snapshot) {
          final pkgName = snapshot.data ?? 'Starting...';
          final FormController controller = FormController();

          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 12),
                Text('Syncing packages... $pkgName').h4,
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: const Text(
                    "Looks like this is first time you're running Nimbox. Give some time to sync with Nimble and fetch your local packages."
                  ).base
                ),
              ],
            ),
          );
        }
      );
    },
  );
}