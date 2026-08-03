import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

class App extends StatelessWidget {
  const App({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Deeplink Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: router ?? appRouter,
    );
  }
}
