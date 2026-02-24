import 'package:flutter/material.dart';

void main() {
  runApp(const WmsApp());
}

class WmsApp extends StatelessWidget {
  const WmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('WMS App Skeleton'),
        ),
      ),
    );
  }
}
