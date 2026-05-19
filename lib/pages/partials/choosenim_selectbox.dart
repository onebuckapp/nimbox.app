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

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../../isolators/sync_choosenim.dart';


class ChoosenimSelect extends StatefulWidget {
  @override
  _ChoosenimSelectState createState() => _ChoosenimSelectState();
}

class _ChoosenimSelectState extends State<ChoosenimSelect> {
  bool _isLoading = false; // Track loading state
  String? _selectedValue; // Track the selected version
  String? selectedValue;
  List<String> nimVersions = [];

  @override
  void initState() {
    super.initState();
    // Fetch Nim versions when the widget is initialized
    fetchNimVersions().then((_) {
      setState(() {
        _selectedValue = selectedValue; // Initialize _selectedValue after fetching versions
        _isLoading = false; // Hide loading indicator
      });
    });
  }

  Future<void> fetchNimVersions() async {
    try {
      final result = await Process.run('choosenim', ['show']);
      if (result.exitCode == 0) {
        // Remove ANSI escape codes from the output
        final output = (result.stdout as String).replaceAll(RegExp(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])'), '');
        final lines = LineSplitter.split(output).toList();

        // Extract versions
        nimVersions = lines
            .where((line) => line.trim().startsWith(RegExp(r'\*|#|\d')))
            .map((line) => line.replaceAll(RegExp(r'[*#]'), '').trim())
            .toList();

        // Extract selected version
        final selectedLine = lines.firstWhere((line) => line.contains('Selected:'));
        selectedValue = selectedLine.split(':').last.trim();
      } else {
        print('Error fetching Nim versions: ${result.stderr}');
      }
    } catch (e) {
      print('Failed to fetch Nim versions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (nimVersions.isEmpty) {
      return const CircularProgressIndicator();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Select<String>(
          itemBuilder: (context, item) {
            return Text(
              '  $item  ', // Add two spaces before and after the text
              softWrap: false, // Prevent wrapping
              overflow: TextOverflow.ellipsis, // Add ellipsis if the text overflows
            );
          },
          popupConstraints: const BoxConstraints(
            maxHeight: 300,
            maxWidth: 200,
          ),
          onChanged: (value) async {
            setState(() {
              _isLoading = true;
            });

            try {
              // Show toast when the process starts
              showToast(
                context: context,
                location: ToastLocation.bottomCenter,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: Text('Switching Nim Version'),
                      subtitle: Text('Switching to version $value...'),
                      trailing: PrimaryButton(
                        size: ButtonSize.small,
                        onPressed: () {
                          overlay.close(); // Close the toast programmatically
                        },
                        child: const Text('Close'),
                      ),
                      trailingAlignment: Alignment.center,
                    ),
                  );
                },
              );

              // Call the isolator to switch the version
              await SyncChoosenimIsolator.switchVersion(value!);
              // Update the selected version and show success toast
              await fetchNimVersions(); // Refresh the versions

              setState(() {
                _selectedValue = value;
                Future.delayed(const Duration(seconds: 2)).then((_) {
                  setState(() {
                    _isLoading = false; // Hide loading indicator after showing success message
                  });
                });
              });

              showToast(
                context: context,
                location: ToastLocation.bottomCenter,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Switched Nim Version'),
                      subtitle: Text('Successfully switched to version $value.'),
                      trailing: PrimaryButton(
                        size: ButtonSize.small,
                        onPressed: () {
                          overlay.close(); // Close the toast programmatically
                        },
                        child: const Text('Close'),
                      ),
                      trailingAlignment: Alignment.center,
                    ),
                  );
                },
              );
            } catch (e) {
              // Show error toast
              setState(() {
                _isLoading = false; // Hide loading indicator
              });

              showToast(
                context: context,
                location: ToastLocation.bottomCenter,
                builder: (context, overlay) {
                  return SurfaceCard(
                    child: Basic(
                      title: const Text('Error Switching Nim Version'),
                      subtitle: Text(e.toString()),
                      trailing: PrimaryButton(
                        size: ButtonSize.small,
                        onPressed: () {
                          overlay.close(); // Close the toast programmatically
                        },
                        child: const Text('Close'),
                      ),
                      trailingAlignment: Alignment.center,
                    ),
                  );
                },
              );
            }
          },
          value: _selectedValue,
          placeholder: const Text('Choosenim'),
          popup: SelectPopup(
            items: SelectItemList(
              children: nimVersions.map((version) {
                return SelectItemButton(
                  value: version,
                  child: Text(
                    '  $version  ', // adding two spaces before & after for better padding
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8), // Add a semi-transparent background
              child: const Center(
                child: CircularProgressIndicator(), // Show loading indicator while switching
              ),
            ),
          ),
      ],
    );
  }
}