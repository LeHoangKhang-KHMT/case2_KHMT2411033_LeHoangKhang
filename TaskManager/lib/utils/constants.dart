import 'package:flutter/foundation.dart';

// Có thể ghi đè khi chạy: flutter run --dart-define=API_URL=http://192.168.1.5:3000/api
const String _override = String.fromEnvironment('API_URL');

String get kBaseUrl {
  if (_override.isNotEmpty) return _override;
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}