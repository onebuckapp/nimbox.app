// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'dart:io';
import 'dart:isolate';
import 'package:meta/meta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Adapter for Isolate.spawn: calls the async isolateEntry and awaits it.
void _isolateEntryAdapter(List<dynamic> message) {
  final entry = message[0] as Future<void> Function(SendPort, [dynamic]);
  final sendPort = message[1] as SendPort;
  final params = message.length > 2 ? message[2] : null;
  entry(sendPort, params);
}

abstract class BaseIsolator<T> extends StateNotifier<T> {
  BaseIsolator(T state) : super(state);

  Isolate? _isolate;
  ReceivePort? _receivePort;

  /// Subclasses can override this to provide a custom entry point.
  @protected
  Future<void> Function(SendPort, [dynamic]) get isolateEntry => BaseIsolator.genericIsolateEntry;

  /// Subclasses can override this to handle messages from the isolate.
  @protected
  Future<bool> onMessage(dynamic message) async {
    // Return true to break/stop listening, false to continue.
    return false;
  }

  Future<void> start({dynamic params}) async {
    if (_isolate != null) return;
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _isolateEntryAdapter,
      [isolateEntry, _receivePort!.sendPort, params],
    );
    await _listenToMessages(_receivePort!);
  }

  Future<void> _listenToMessages(ReceivePort receivePort) async {
    await for (var message in receivePort) {
      final shouldBreak = await onMessage(message);
      if (shouldBreak) {
        receivePort.close();
        kill();
        break;
      }
    }
  }

  void kill() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  void dispose() {
    kill();
    super.dispose();
  }

  /// Generic isolate entry: runs a shell command and sends result.
  static Future<void> genericIsolateEntry(SendPort sendPort, [dynamic params]) async {
    try {
      final command = params?['command'] as String?;
      final arguments = (params?['arguments'] as List?)?.cast<String>() ?? <String>[];
      if (command == null) throw Exception('No command provided');
      final result = await Process.run(command, arguments);
      // print('Command stdout: ${result.stdout}');
      // print('Command stderr: ${result.stderr}');
      if (result.exitCode == 0) {
        sendPort.send({'status': 'done', 'stdout': result.stdout});
      } else {
        sendPort.send({'error': 'Command failed with exit code ${result.exitCode}\n${result.stderr}'});
      }
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }
}