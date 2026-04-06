import 'package:flutter/material.dart';

class AppPageBody extends StatelessWidget {
  const AppPageBody({
    required this.child,
    super.key,
    this.top = false,
    this.bottom = true,
    this.minimumBottom = 12,
  });

  final Widget child;
  final bool top;
  final bool bottom;
  final double minimumBottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      minimum: EdgeInsets.only(bottom: bottom ? minimumBottom : 0),
      child: child,
    );
  }
}
