import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppEnvironment { local, dev, prod }

class AppConfig {
  static const String _envKey = 'app_selected_environment';
  static const String _customUrlKey = 'app_custom_api_url';

  // Read environment from compile-time flag: flutter run --dart-define=ENV=dev
  static const String _compileEnv = String.fromEnvironment('ENV', defaultValue: 'local');

  static AppEnvironment _currentEnv = _parseEnv(_compileEnv);
  static String? _customApiUrl;

  static AppEnvironment get environment => _currentEnv;

  static AppEnvironment _parseEnv(String str) {
    switch (str.toLowerCase()) {
      case 'dev':
      case 'staging':
        return AppEnvironment.dev;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return AppEnvironment.local;
    }
  }

  /// Initialize environment config from SharedPreferences (retains user setting across restarts)
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnv = prefs.getString(_envKey);
    if (savedEnv != null) {
      _currentEnv = _parseEnv(savedEnv);
    }
    _customApiUrl = prefs.getString(_customUrlKey);
  }

  /// Change active environment dynamically at runtime
  static Future<void> setEnvironment(AppEnvironment env) async {
    _currentEnv = env;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envKey, env.name);
  }

  /// Set custom API URL override
  static Future<void> setCustomApiUrl(String? customUrl) async {
    _customApiUrl = customUrl;
    final prefs = await SharedPreferences.getInstance();
    if (customUrl != null && customUrl.isNotEmpty) {
      await prefs.setString(_customUrlKey, customUrl);
    } else {
      await prefs.remove(_customUrlKey);
    }
  }

  /// Returns active API base URL for current environment & device platform
  static String get baseUrl {
    if (_customApiUrl != null && _customApiUrl!.trim().isNotEmpty) {
      return _customApiUrl!.trim();
    }

    switch (_currentEnv) {
      case AppEnvironment.dev:
      case AppEnvironment.prod:
        return 'https://cheepper-bills-backend.vercel.app/api/v1';
      case AppEnvironment.local:
      default:
        return 'https://cheepper-bills-backend.vercel.app/api/v1';
    }
  }

  static String get appName {
    switch (_currentEnv) {
      case AppEnvironment.dev:
        return 'Cheepper Bills (DEV)';
      case AppEnvironment.prod:
        return 'Cheepper Bills';
      case AppEnvironment.local:
      default:
        return 'Cheepper Bills (LOCAL)';
    }
  }

  static String get environmentLabel {
    switch (_currentEnv) {
      case AppEnvironment.dev:
        return 'STAGING / DEV';
      case AppEnvironment.prod:
        return 'PRODUCTION';
      case AppEnvironment.local:
      default:
        return 'LOCAL (DEV)';
    }
  }

  static bool get isProduction => _currentEnv == AppEnvironment.prod;
  static bool get showDebugBanner => _currentEnv != AppEnvironment.prod;
}
