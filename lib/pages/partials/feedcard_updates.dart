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

import 'package:xml/xml.dart';
import 'package:flutter/animation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import './feedcard_service.dart';
import '../../utils/util.dart';

class FeedCardUpdates extends FeedCardBase {
  const FeedCardUpdates({Key? key})
      : super(key: key, url: 'https://github.com/nim-lang/Nim/releases.atom');

  @override
  State<FeedCardUpdates> createState() => _FeedCardUpdatesState();
}

class _FeedCardUpdatesState extends FeedCardBaseState<FeedCardUpdates> with SingleTickerProviderStateMixin {
  String? _version;
  String? _description;
  String? _releaseLink;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void onXmlFetched(String xml) {
    final document = XmlDocument.parse(xml);
    final entry = document.findAllElements('entry').first;
    final rawDescription = entry.findElements('content').first.text;

    setState(() {
      _version = entry.findElements('title').first.text;
      _description = rawDescription.replaceAll(RegExp(r'<[^>]*>'), '');
      _releaseLink = entry.findElements('link').first.getAttribute('href');
      isLoading = false;
    });
  }

  @override
  Widget buildPlaceholder() =>
    Card(
      padding: const EdgeInsets.all(0),
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 280,
        decoration: const BoxDecoration(
          image: null, // Remove static image decoration
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/kunal-patil-8ZKlgI_G-mw-unsplash.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            ShadcnSkeletonizerConfigLayer(
              theme: ThemeData(
                colorScheme: ColorSchemes.darkZinc.zinc,
              ),
              child: Container(
                padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Column(
                  children:[
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("xxxx"),
                          const SizedBox(height: 8),
                          Text("Update Available", style: TextStyle(fontSize: 32)).light,
                          const SizedBox(height: 8),
                          Text("Lorem ipsum dolor sit amet").small,
                        ],
                      ),
                    ),
                  ]
                )
              ).asSkeletonSliver(),
            )
          ]
        )
      )
    );

  @override
  Widget buildContent() => _innerContainer(
        version: _version ?? 'Unknown Version',
        description: _description ?? 'No description available.',
      );

  Widget _innerContainer({required String version, required String description, bool isLoading = false}) {
    return GestureDetector(
      onTap: () {
        if (_releaseLink != null) {
          openUrl(_releaseLink!);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          padding: const EdgeInsets.all(0),
          borderRadius: BorderRadius.circular(15),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 280,
            decoration: const BoxDecoration(
              image: null, // Remove static image decoration
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/kunal-patil-8ZKlgI_G-mw-unsplash.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 24, right: 16, top: 16, bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    children:[
                      Align(
                        alignment: Alignment.topRight,
                        child: SvgPicture.asset(
                          'assets/nim-icon.svg',
                          width: 32,
                          height: 32,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SecondaryBadge(child: Text(version).semiBold.small),
                            const SizedBox(height: 8),
                            Text("Update Available", style: TextStyle(fontSize: 32)).light,
                            const SizedBox(height: 8),
                            Text(description).small,
                          ],
                        ),
                      ),
                    ]
                  )
                ),
              ],
            ),
          ),
        )
      )
    );
  }
}