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

import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NimboxSkeletonizerConfigLayer extends StatelessWidget {
  final ThemeData theme;
  final Widget child;

  const NimboxSkeletonizerConfigLayer({
    super.key,
    required this.theme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonizerConfig(
      data: SkeletonizerConfigData(
        effect: PulseEffect(
          duration: const Duration(seconds: 5),
          from: const Color(0xfffafafa), // Example colors
          to: const Color(0xff7f22fe),
        ),
        enableSwitchAnimation: true,
      ),
      child: child,
    );
  }
}

// Function to apply Skeletonizer to any widget
Widget applyNimboxSkeleton({
  required Widget child,
  bool enabled = true,
  bool leaf = false,
  Widget? replacement,
  bool unite = false,
  AsyncSnapshot? snapshot,
}) {
  if (snapshot != null) {
    enabled = !snapshot.hasData;
  }
  if (leaf) {
    return Skeleton.leaf(
      enabled: enabled,
      child: child,
    );
  }
  if (replacement != null) {
    return Skeleton.replace(
      replace: enabled,
      child: replacement,
    );
  }
  if (unite) {
    return Skeleton.unite(
      unite: enabled,
      child: child,
    );
  }
  return Skeletonizer(
    enabled: enabled,
    child: child,
  );
}