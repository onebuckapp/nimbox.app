import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'package:markdown_widget/markdown_widget.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../isolators/build_docs.dart';

import '../services/notification_service.dart';
import './partials/navigation.dart';

final FormController controller = FormController();

Widget buildSheet(BuildContext context) {
  void saveProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profile updated'),
          content: Text('Content: ${controller.values}'),
          actions: [
            PrimaryButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  return Container(
    padding: const EdgeInsets.all(24),
    constraints: const BoxConstraints(maxWidth: 600, minWidth: 500),
    child: Form(
      controller: controller,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: const Text('Edit profile').large().medium(),
              ),
              TextButton(
                density: ButtonDensity.icon,
                child: const Icon(Icons.close),
                onPressed: () {
                  closeSheet(context);
                },
              ),
            ],
          ),
          const Gap(8),
          const Text('Make changes to your profile here. Click save when you\'re done.').muted(),
          const Gap(16),
          FormTableLayout(
            rows: [
              FormField<String>(
                key: const FormKey(#name),
                label: const Text('Name'),
                validator:
                    const NotEmptyValidator() & const LengthValidator(min: 4),
                child: const TextField(
                  initialValue: 'Thito Yalasatria Sunarya',
                  placeholder: Text('Your fullname'),
                ),
              ),
              FormField<String>(
                key: const FormKey(#username),
                label: const Text('Username'),
                validator:
                    const NotEmptyValidator() & const LengthValidator(min: 4),
                child: const TextField(
                  initialValue: '@sunarya-thito',
                  placeholder: Text('Your username'),
                ),
              ),
            ],
          ),
          const Gap(16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FormErrorBuilder(
              builder: (context, errors, child) {
                return PrimaryButton(
                  onPressed: errors.isNotEmpty
                      ? null
                      : () {
                          context.submitForm().then(
                            (value) {
                              if (value.errors.isEmpty) {
                                closeSheet(context).then(
                                  (value) {
                                    saveProfile();
                                  },
                                );
                              }
                            },
                          );
                        },
                  child: const Text('Save changes'),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class CardCarousel extends StatelessWidget {
  final List<Widget> yourCardList = List.generate(
    5,
    (index) => Card(
      child: Container(
        width: 250,
        height: 160,
        alignment: Alignment.center,
        child: Text(
          'Card ${index + 1}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Similar packages').h3,
          ],
        ),
        const SizedBox(height: 8),
        CarouselSlider(
          options: CarouselOptions(
            height: 150,
            enlargeCenterPage: false,
            padEnds: true, // Ensures no extra padding at ends
            viewportFraction: 0.33,
          ),
          items: yourCardList.map((i) {
            return Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Card(
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.all(0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("chalk").medium.h4,
                            const SizedBox(height: 8),
                            Text(
                              "Software artifact metadata to make it easy to tie deployments to source code and collect metadata.",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(height: 1.7)
                            ).light.small,
                          ],
                        ),
                      ),
                    ),
                  )
                );
              },
            );
          }).toList(),
        )
      ]
    );
  }
}

class SimpleLineChart extends StatelessWidget {
  // Example data: downloads per day for 30 days
  // final List<int> downloadsPerDay = [
  //   120, 144, 96, 180, 240, 40, 264, 300, 228, 204,
  //   252, 276, 240, 216, 192, 168, 156, 180, 204, 228,
  //   252, 264, 288, 312, 110, 324, 30, 276, 264, 240
  // ];
  final List<int> downloadsPerDay = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child:
      downloadsPerDay.length == 0
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No download data available').xSmall.muted,
          ),
        )
      : LineChart(
          LineChartData(
            gridData: FlGridData(show: false), // Hide grid lines
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Hide left axis numbers
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Hide top axis numbers
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Hide right axis numbers
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    int day = value.toInt() + 1;
                    if (day == 1 || day == 30 || day % 5 == 0) {
                      // return Text('D$day', style: TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 0,
                ),
              ),
            ),
            borderData: FlBorderData(show: false), // Optionally hide border
            minX: 0,
            maxX: (downloadsPerDay.length - 1).toDouble(),
            minY: 0,
            maxY: (downloadsPerDay.reduce((a, b) => a > b ? a : b) * 1.2).roundToDouble(),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (int i = 0; i < downloadsPerDay.length; i++)
                    FlSpot(i.toDouble(), downloadsPerDay[i].toDouble()),
                ],
                isCurved: true,
                barWidth: 2,
                color: Colors.blue[400],
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.blue.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

// Riverpod providers for tab index and docs building state
final packageTabIndexProvider = StateProvider<int>((ref) => 0);
final isBuildingDocsProvider = StateProvider<bool>((ref) => false);
// final buildStateProvider = StateNotifierProvider<BuildState, bool>((ref) => BuildState());
final buildStateProvider = StateNotifierProvider.family<BuildState, bool, String>(
  (ref, packageTitle) => BuildState(),
);

class PackagePage extends ConsumerStatefulWidget {
  const PackagePage({
    super.key,
    required this.title,
    required this.isDark,
    // required this.onThemeToggle,
  });

  final String title;
  final bool isDark;

  @override
  ConsumerState<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends ConsumerState<PackagePage> with WidgetsBindingObserver {

  final List<String> tags = ['chart', 'vizualization', 'graph', 'visualization', 'data', 'flutter', 'dart', 'mobile', 'web', 'desktop'];

  // final sampleMarkdown = MarkdownPage('''# This is just a test''');

  renderNoDataAvailable() {
    return Alert(
      title: Text('No data available').h4,
      content: Row(
        children: [
          Expanded(
            child: Text(
              'This package does not have any data available at the moment. Please check back later or refer to the documentation for more information.',
              softWrap: true,
            ),
          ),
        ],
      ),
      leading: Icon(Icons.info_outline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(packageTabIndexProvider);

    final isBuilding = ref.watch(buildStateProvider(widget.title));
    final buildState = ref.read(buildStateProvider(widget.title).notifier);

    return Scaffold(
      child: Stack(
        children: [
          // Main content and sidebar
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 5),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0, left: 90, right: 90, bottom: 90),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main area
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 50),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(widget.title).medium.h1,
                                      const SizedBox(width: 8),
                                      IconButton.secondary(
                                        icon: const Icon(Icons.copy),
                                        density: ButtonDensity.compact,
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: 'nimble install ${widget.title}'));
                                        },
                                      ),
                                      Spacer(),
                                      Tooltip(
                                        tooltip: TooltipContainer(
                                          backgroundColor: Theme.of(context).colorScheme.secondary,
                                          child: Text('Open URL in browser'),
                                        ),
                                        child: GhostButton(
                                          child: const Text('Visit Repository'),
                                          trailing: const Icon(LucideIcons.externalLink),
                                          // onPressed: () => openUrl('https://pub.dev/packages/chalk')
                                          onPressed: () => print('Open package URL in browser'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Tooltip(
                                        tooltip: TooltipContainer(
                                          backgroundColor: Theme.of(context).colorScheme.secondary,
                                          child: Text('Install package locally via Nimble'),
                                        ),
                                        // child:  PrimaryButton(
                                        //   child: const Text('Install package'),
                                        //   trailing: const Icon(Icons.add),
                                        //   onPressed: () {},
                                        // ),
                                        child:  OutlineButton(
                                          child: const Text('Uninstall'),
                                          trailing: const Icon(RadixIcons.cross2),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: const Text('Uninstall package'),
                                                  content: const Text('Are you sure you want to uninstall this package?'),
                                                  actions: [
                                                    OutlineButton(
                                                      child: const Text('Cancel'),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                    PrimaryButton(
                                                      child: const Text('OK'),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text('Updated 3 days ago').muted().small,
                                    const SizedBox(width: 8),
                                    Text('•').muted().small(),
                                    const SizedBox(width: 8),
                                    PrimaryBadge(
                                      child: Text('v1.2.3').medium.textSmall,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('•').muted().small,
                                    const SizedBox(width: 8),
                                    OutlineBadge(
                                      child: Row(
                                        children: [
                                          Icon(BootstrapIcons.patchCheckFill),
                                          SizedBox(width: 4),
                                          Text('Compatible with Nim >= 2.0').small()
                                        ],
                                      )
                                    )
                                  ]
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TabList(
                                        index: index,
                                        onChanged: (value) {
                                          ref.read(packageTabIndexProvider.notifier).state = value;
                                        },
                                        children: [
                                          TabItem(child: Text('Readme').medium),
                                          TabItem(child: Text('Examples').medium),
                                          TabItem(child: Text('Dependencies').medium),
                                          TabItem(child: Text('Changelog').medium),
                                          TabItem(
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text('Versions').medium,
                                                const SizedBox(width: 6),
                                                OutlineBadge(
                                                  child: Text('5', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            )
                                          ),
                                          TabItem(child: Text('Tests').medium),
                                        ],
                                      ),
                                      const Gap(16),
                                      Stack(
                                        children: [
                                          if (index == 0)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              // child: sampleMarkdown
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                          if (index == 1)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                          if (index == 2)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                          if (index == 3)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                          if (index == 4)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                          if (index == 5)
                                            Card(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  renderNoDataAvailable(),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Move the carousel here, under the main section area
                                const SizedBox(height: 32),
                                // Row(
                                //   children: [
                                //     Text("Tags").h4,
                                //     const SizedBox(width: 12),
                                //     ...tags.map((tag) => Padding(
                                //       padding: const EdgeInsets.only(right: 8.0),
                                //       child: OutlineBadge(
                                //         child: Text(tag).small()
                                //       ),
                                //     )).toList()
                                //   ],
                                // ),
                                // const SizedBox(height: 32),
                                // Column(
                                //   crossAxisAlignment: CrossAxisAlignment.start,
                                //   children: [
                                //     CardCarousel(),
                                //   ],
                                // )
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                          // Sidebar
                          SizedBox(
                            width: 250,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Card(
                                    padding: const EdgeInsets.all(0),
                                    child: SimpleLineChart()
                                  ),
                                  const SizedBox(height: 20),
                                  Card(
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 5),
                                          child:  Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('API Reference').semiBold(),
                                              const SizedBox(height: 4),
                                              const Text('Build and view the full API reference for this package.').muted().small(),
                                              const SizedBox(height: 5),
                                            ]
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Align(
                                                alignment: Alignment.center,
                                                child: SecondaryButton(
                                                  child: const Text('Open Documentation'),
                                                  onPressed: () {
                                                    openSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return buildSheet(context);
                                                      },
                                                      position: OverlayPosition.end,
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Divider(),
                                              Align(
                                                alignment: Alignment.center,
                                                child: Column(
                                                  children: [
                                                    LinkButton(
                                                      child: isBuilding ? Text('Rebuilding...') : Text('Rebuild'),
                                                      leading: isBuilding ? SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(strokeWidth: 2)
                                                      ) : null,
                                                      onPressed: isBuilding
                                                        ? null
                                                        : () async => await buildState.startBuild(
                                                            command: '/Users/georgelemon/.nimble/bin/nim',
                                                            arguments: ['jsondoc', '--project', '--index:off', '--out:/Users/georgelemon/.boogie/docs/gccjit', '/Users/georgelemon/.nimble/pkgs2/gccjit-0.1.0-95877722619d5d2e55ea8cc0b9e0109fdfaa7bce/gccjit.nim']
                                                          ),
                                                    ),
                                                    const Text('Last built on 20th June 2024').xSmall.muted
                                                  ]
                                                )
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Card(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Description').semiBold.small,
                                        const SizedBox(height: 4),
                                        const SelectableText('A highly customizable Flutter chart library that supports Line Chart, Bar Chart, Pie Chart, Scatter Chart, and Radar Chart.').muted().small(),
                                        const SizedBox(height: 15),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Published by').semiBold.small,
                                            const SizedBox(height: 4),
                                            const Text('OpenPeeps').muted.small,
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('License').semiBold.small,
                                            const SizedBox(height: 4),
                                            const Text('GPL-v3').muted.small,
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 20),
                                      const Text('Tags').h4,
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: tags.map((tag) => Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: OutlineBadge(
                                              child: Text(tag).small()
                                            ),
                                          )).toList()
                                      ),
                                    ]
                                  )
                                ]
                              )
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Logo at the top
          renderNavigationBarWithShadow(context),

          // Footer at the bottom
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 150),
          //     color: Colors.zinc[widget.isDark ? 900 : 50],
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         Row(
          //           children: [
          //             Text('© ${DateTime.now().year}').xSmall,
          //             const SizedBox(width: 12),
          //             const Text('Made by Humans from OpenPeeps').xSmall,
          //           ],
          //         ),
          //         Wrap(
          //           spacing: 24,
          //           children: [
          //             LinkButton(
          //               onPressed: () => GoRouter.of(context).push('/terms'),
          //               child: const Text('Terms & Conditions').xSmall,
          //             ),
          //             LinkButton(
          //               onPressed: () => GoRouter.of(context).push('/privacy'),
          //               child: const Text('Privacy').xSmall,
          //             ),
          //             LinkButton(
          //               onPressed: () => GoRouter.of(context).push('/imprint'),
          //               child: const Text('Imprint').xSmall,
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      )
    );
  }
}