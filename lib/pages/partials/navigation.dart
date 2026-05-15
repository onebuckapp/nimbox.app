// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp


import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart'; // Add this import

Widget renderNavigationBarWithShadow(BuildContext context) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.transparent,
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.background.withOpacity(1),
          blurRadius: 25,
          spreadRadius: 20,
          offset: Offset(0, 0),
        ),
      ],
    ),
    child: renderNavigation(context),
  );
}

Widget renderNavigationMenu(BuildContext context) {
  return SizedBox(
    width: MediaQuery.of(context).size.width - 50,
    height: 46,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 400,
          child: NavigationMenu(
            children: [
              NavigationMenuItem(
                onPressed: () => GoRouter.of(context).go('/packages'),
                child: const Text('Installed Packages'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          width: 430,
          child: const TextField(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            placeholder: Text('Search in packages, docs and more...'),
          ),
        ),
        Spacer(),
      ]
    )
  );
}

Widget renderNavigation(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 10, right: 10, top: 32, bottom: 0),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // Only the navigation bar is height-constrained
        OutlinedContainer(
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Color(0xff171921),
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 90), // Reserve space for logo
                renderNavigationMenu(context),
              ],
            ),
          ),
        ),
        // Logo can overflow above the navigation bar
        Positioned(
          top: -16,
          left: 5,
          child: SizedBox(
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                GoRouter.of(context).go('/');
              },
              child: Image.asset(
                'assets/nimbox_logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}