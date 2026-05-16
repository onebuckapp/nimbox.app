// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

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