import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  // 設定項目のキー
  static const String _showScreenshotsKey = 'show_screenshots';

  // スクリーンショットを表示するかどうかの設定を取得
  static Future<bool> getShowScreenshots() async {
    final prefs = await SharedPreferences.getInstance();
    // デフォルトでは表示する（true）
    return prefs.getBool(_showScreenshotsKey) ?? true;
  }

  // スクリーンショットを表示するかどうかの設定を保存
  static Future<bool> setShowScreenshots(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_showScreenshotsKey, value);
  }
}
