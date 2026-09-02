import 'package:flutter/material.dart';

import 'home_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen(title: 'Favorites', favoritesOnly: true);
  }
}
