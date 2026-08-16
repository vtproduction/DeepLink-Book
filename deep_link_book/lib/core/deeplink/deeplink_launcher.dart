import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class DeeplinkLauncher {
  const DeeplinkLauncher();

  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final deeplinkLauncherProvider = Provider<DeeplinkLauncher>((ref) {
  return const DeeplinkLauncher();
});
