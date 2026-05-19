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
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'base_isolator.dart';

class SyncChoosenimIsolator extends BaseIsolator<void> {
  SyncChoosenimIsolator() : super(null);

  static Future<void> switchVersion(String version) async {
    final isolator = SyncChoosenimIsolator();

    // Start the isolate to switch the version
    await isolator.start(params: {'command': 'choosenim', 'arguments': ['update', version]});
  }

  @override
  Future<bool> onMessage(dynamic message) async {
    if (message is Map && message.containsKey('error')) {
      // Return error message to the caller
      print('Error: ${message['error']}');
    } else if (message is Map && message['status'] == 'done') {
      // Return success message to the caller
      print('Success: ${message['stdout']}');
    }
    return true; // Stop listening after one message
  }
}