import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlLauncherFunction = Future<bool> Function(
  Uri url, {
  LaunchMode mode,
});

class UrlLauncherService {
  static UrlLauncherFunction? _mockLauncher;

  @visibleForTesting
  static set mockLauncher(UrlLauncherFunction? mock) {
    _mockLauncher = mock;
  }

  static Future<bool> launchUrlExternal(Uri url) async {
    if (_mockLauncher != null) {
      return _mockLauncher!(url, mode: LaunchMode.externalApplication);
    }
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
