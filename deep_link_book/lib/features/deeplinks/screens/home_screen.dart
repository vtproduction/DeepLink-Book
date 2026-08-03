import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Deeplink Manager home')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Deeplink',
        onPressed: () => context.pushNamed(AppRoute.addDeeplink.name),
        child: const Icon(Icons.add),
      ),
    );
  }
}
