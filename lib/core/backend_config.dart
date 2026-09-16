import 'dart:io';
import 'package:flutter/foundation.dart';

class BackendConfig {
  // Set via: flutter run --dart-define=BACKEND_URL=http://192.168.x.x:5000/api
  static const String _envUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    if (kIsWeb) return 'http://localhost:5000/api';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.31.97.231:5000/api';
    return 'http://localhost:5000/api';
  }
}
