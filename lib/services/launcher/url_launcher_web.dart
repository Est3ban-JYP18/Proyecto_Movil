// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class PlatformUrlLauncher {
  static Future<bool> openUrl(String url) async {
    try {
      html.window.open(url, '_blank');
      return true;
    } catch (_) {
      try {
        html.window.location.href = url;
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
