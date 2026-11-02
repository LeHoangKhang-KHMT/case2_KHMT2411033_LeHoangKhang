import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiClient {
  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$kBaseUrl$path'));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}