import 'package:intl/intl.dart';
import '../models/task.dart';
import 'api_client.dart';

class TaskService {
  final ApiClient _api = ApiClient();
  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  Future<Task> createTask({
    required String title,
    required String description,
    required String priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'priority': priority,
    };
    if (startDate != null) body['startDate'] = _apiDate.format(startDate);
    if (dueDate != null) body['dueDate'] = _apiDate.format(dueDate);

    final data = await _api.post('/tasks', body);
    return Task.fromJson(data['task'] as Map<String, dynamic>);
  }
}