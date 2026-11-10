import 'api_client.dart';

class StatisticsService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> tasks() => _api.get('/statistics/tasks');
  Future<Map<String, dynamic>> assignments() => _api.get('/statistics/assignments');
  Future<Map<String, dynamic>> deadlines() => _api.get('/statistics/deadlines');
}