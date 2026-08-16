import 'package:app_links/app_links.dart';

class DeeplinkListener {
  const DeeplinkListener();

  Future<Uri?> getInitialUri() {
    return AppLinks().getInitialLink();
  }

  Stream<Uri> get uriStream {
    return AppLinks().uriLinkStream;
  }
}
