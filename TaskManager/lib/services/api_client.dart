import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  Map<String, String> _headers() => {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$kBaseUrl$path'), headers: _headers());
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw ApiException(data['message']?.toString() ?? 'Loi may chu', res.statusCode);
  }
}