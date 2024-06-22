import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {

  static final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static Future<String?> getString(String key) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<bool> setString(String key, String value) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.setString(key, value);
  }

  static Future<bool> setInt(String key, int value) async { 
    final SharedPreferences prefs = await _prefs;
    return prefs.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getInt(key);
  }

  static Future<bool> clear() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.clear();
  }
}