// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:xml/xml.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import './feedcard_service.dart';
import '../../utils/util.dart';

class FeedCardForum extends FeedCardBase {
  const FeedCardForum({Key? key})
      : super(key: key, url: 'https://forum.nim-lang.org/threadActivity.xml');

  @override
  State<FeedCardForum> createState() => _FeedCardForumState();
}

class _FeedCardForumState extends FeedCardBaseState<FeedCardForum> {
  List<Map<String, String>> _entries = [];
  int? _hoveredIndex;

  @override
  void onXmlFetched(String xml) {
    final document = XmlDocument.parse(xml);
    final entries = document.findAllElements('entry').map((entry) => {
      'title': entry.findElements('title').first.text,
      'link': entry.findElements('link').first.getAttribute('href') ?? '',
      'author': entry.findElements('author').first.findElements('name').first.text,
      'updated': entry.findElements('updated').first.text,
    }).toList();

    setState(() {
      _entries = entries;
      isLoading = false;
    });
  }

  @override
  Widget buildPlaceholder() => 
    ShadcnSkeletonizerConfigLayer(
      theme: ThemeData(
        colorScheme: ColorSchemes.darkZinc.zinc,
        radius: 0.6,
        density: Density.reducedDensity,
        surfaceOpacity: 0.8,
        surfaceBlur: 8,
      ),
      child:
        ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: double.infinity, color: Colors.white.withOpacity(0.06)),
              const SizedBox(height: 4),
              Container(height: 12, width: 150, color: Colors.white.withOpacity(0.06)),
            ])),
          ]),
        ),
      )
    );

  @override
  Widget buildContent() => _entries.isEmpty
      ? const Center(child: Text('No entries found', style: TextStyle(color: Colors.slate)))
      : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 0),
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            final entry = _entries[index];
            return GestureDetector(
              onTap: () { 
                final url = entry['link'] ?? '';
                if (url.isNotEmpty) {
                  openUrl(url);
                }
               },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _hoveredIndex == index ? Colors.white.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                      child: Icon(TablerIcons.message, size: 18, color: Colors.white.withOpacity(0.5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(entry['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('By ${entry['author']} • ${entry['updated']}',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.35)),
                      ),
                    ])),
                    const SizedBox(width: 8),
                    Icon(TablerIcons.chevron_right, size: 14, color: Colors.white.withOpacity(0.2)),
                  ]),
                ),
              ),
            );
          },
        );

  @override
  Widget build(BuildContext context) {
    return Card(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(0),
      child: Container(
        width: 620,
        constraints: const BoxConstraints(maxHeight: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(TablerIcons.message, size: 20, color: Colors.slate),
                const SizedBox(width: 6),
                const Text('Forum Feed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(child: super.build(context)),
          ],
        ),
      ),
    );
  }
}