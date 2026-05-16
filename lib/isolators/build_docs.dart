// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:isolate';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './base_isolator.dart';

class BuildState extends BaseIsolator<bool> {
  BuildState() : super(false);

  String? _command;
  List<String>? _arguments;

  /// Starts the build by running a shell command in an isolate.
  Future<void> startBuild({required String command, List<String> arguments = const []}) async {
    if (state) return;
    state = true;
    _command = command;
    _arguments = arguments;
    print('Start isolated task: $command $arguments');
    await start(params: {'command': command, 'arguments': arguments});
  }

  @override
  Future<bool> onMessage(dynamic message) async {
    print('Received message: $message');
    if (message is Map && message['status'] == 'done') {
      state = false;
      print('Build finished, state set to false');
      return true; // stop listening, close receivePort, kill isolate
    } else if (message is Map && message['error'] != null) {
      state = false;
      print('Build failed: ${message['error']}');
      return true; // stop listening, close receivePort, kill isolate
    }
    return false; // continue listening
  }
}

// // Example usage:
// final buildState = BuildState();

// void runExample() async {
//   // Run the 'ls -la' command
//   await buildState.startBuild(command: 'ls', arguments: ['-la']);
// }
// // Example usage:
// final buildState = BuildState();

// void runExample() async {
//   // Run the 'ls -la' command
//   await buildState.startBuild(command: 'ls', arguments: ['-la']);
// }

