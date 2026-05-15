// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:async';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> showSyncingDialog(BuildContext context, Stream<String> syncStream) async {
  await showDialog(
    context: context,
    // barrierDismissible: false,
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