import 'package:flutter/material.dart';

/// Centers [child] and caps its width so pages don't stretch edge-to-edge
/// on large / desktop-web viewports. Below [maxWidth] (e.g. on phones) it
/// behaves like a normal full-width widget — the constraint simply never
/// binds.
class MaxWidthContainer extends StatelessWidget {
  const MaxWidthContainer({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}