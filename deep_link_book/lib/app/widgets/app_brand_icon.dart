import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22D3EE), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322D3EE),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const SizedBox.square(
        dimension: 42,
        child: Icon(Icons.link, color: Colors.white, size: 23),
      ),
    );
  }
}
