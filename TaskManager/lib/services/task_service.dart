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
      Future<List<Task>> listTasks({
    String scope = 'all',
    String q = '',
    String? status,
    String? priority,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    final params = <String, String>{
      'scope': scope,
      'sortBy': sortBy,
      'order': order,
    };
    if (q.isNotEmpty) params['q'] = q;
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;

    final query = Uri(queryParameters: params).query;
    final data = await _api.get('/tasks?$query');
    final list = data['tasks'] as List<dynamic>;
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

    Future<TaskDetail> getTask(String id) async {
    final data = await _api.get('/tasks/$id');
    return TaskDetail(
      task: Task.fromJson(data['task'] as Map<String, dynamic>),
      access: TaskAccess.fromJson(data['access'] as Map<String, dynamic>),
    );
  }

    Future<Task> updateTask(
    String id, {
    required String title,
    required String description,
    required String priority,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final data = await _api.put('/tasks/$id', {
      'title': title,
      'description': description,
      'priority': priority,
      'startDate': startDate == null ? null : _apiDate.format(startDate),
      'dueDate': dueDate == null ? null : _apiDate.format(dueDate),
    });
    return Task.fromJson(data['task'] as Map<String, dynamic>);
  }

    Future<void> deleteTask(String id) async {
    await _api.delete('/tasks/$id');
  }
    Future<void> updateStatus(String id, String status) async {
    await _api.patch('/tasks/$id/status', {'status': status});
  }
}