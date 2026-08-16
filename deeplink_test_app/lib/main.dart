import 'package:flutter/material.dart';

import 'deeplink_listener.dart';
import 'home_screen.dart';

void main() {
  runApp(const DeeplinkTestApp(listener: DeeplinkListener()));
}

class DeeplinkTestApp extends StatelessWidget {
  const DeeplinkTestApp({super.key, this.listener});

  final DeeplinkListener? listener;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deeplink Test App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: HomeScreen(listener: listener),
    );
  }
}
