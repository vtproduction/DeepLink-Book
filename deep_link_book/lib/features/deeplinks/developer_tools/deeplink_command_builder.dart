String buildAdbCommand(String url) {
  return 'adb shell am start -a android.intent.action.VIEW -d ${shellQuote(url)}';
}

String buildSimctlCommand(String url) {
  return 'xcrun simctl openurl booted ${shellQuote(url)}';
}

String shellQuote(String value) {
  if (value.isEmpty) {
    return "''";
  }

  return "'${value.replaceAll("'", "'\"'\"'")}'";
}
