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

import 'package:http/http.dart' as http;
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FeedCacheService {
  static final Map<String, String> _cachedXml = {};
  static final Map<String, DateTime> _lastFetchTime = {};
  static const Duration fetchInterval = Duration(minutes: 60);

  static bool isCacheValid(String url) {
    final lastFetch = _lastFetchTime[url];
    if (_cachedXml[url] == null || lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < fetchInterval;
  }

  static String? getCached(String url) => _cachedXml[url];

  static void set(String url, String xml) {
    _cachedXml[url] = xml;
    _lastFetchTime[url] = DateTime.now();
  }
}

abstract class FeedCardBase extends StatefulWidget {
  final String url;
  const FeedCardBase({Key? key, required this.url}) : super(key: key);
}

abstract class FeedCardBaseState<T extends FeedCardBase> extends State<T> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIfNeeded();
  }

  Future<void> _fetchIfNeeded() async {
    if (FeedCacheService.isCacheValid(widget.url)) {
      print('Using cached data for ${widget.url}');
      onXmlFetched(FeedCacheService.getCached(widget.url)!);
    } else {
      setState(() => isLoading = true);
      await _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        FeedCacheService.set(widget.url, response.body);
        onXmlFetched(response.body);
      } else {
        throw Exception('Failed to load feed');
      }
    } catch (e) {
      print('Error fetching feed: $e');
      // setState(() => isLoading = false);
    }
  }

  /// Called when XML is available (fresh or cached). Parse and call setState here.
  void onXmlFetched(String xml);

  /// Loading placeholder widget
  Widget buildPlaceholder();

  /// Content widget when data is loaded
  Widget buildContent();

  @override
  Widget build(BuildContext context) {
    return isLoading ? buildPlaceholder() : buildContent();
  }
}
