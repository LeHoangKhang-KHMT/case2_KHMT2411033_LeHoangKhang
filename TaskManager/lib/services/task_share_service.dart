import '../models/task_share.dart';
import 'api_client.dart';

class TaskShareService {
  final ApiClient _api = ApiClient();

  // ----- Giao việc -----
  Future<List<Person>> listAssignees(String taskId) async {
    final data = await _api.get('/tasks/$taskId/assignees');
    return (data['assignees'] as List<dynamic>)
        .map((e) => Person.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Trả về danh sách email không tìm thấy tài khoản.
  Future<List<String>> addAssignees(String taskId, List<String> emails) async {
    final data = await _api.post('/tasks/$taskId/assignees', {'emails': emails});
    return List<String>.from(data['notFound'] ?? []);
  }

  Future<void> setPrimary(String taskId, String userId, bool isPrimary) async {
    await _api.patch('/tasks/$taskId/assignees/$userId', {'isPrimary': isPrimary});
  }

  Future<void> removeAssignee(String taskId, String userId) async {
    await _api.delete('/tasks/$taskId/assignees/$userId');
  }

  // ----- Chia sẻ -----
  Future<List<TaskShare>> listShares(String taskId) async {
    final data = await _api.get('/tasks/$taskId/shares');
    return (data['shares'] as List<dynamic>)
        .map((e) => TaskShare.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> addShares(
    String taskId,
    List<String> emails,
    String permission,
  ) async {
    final data = await _api.post('/tasks/$taskId/shares', {
      'emails': emails,
      'permission': permission,
    });
    return List<String>.from(data['notFound'] ?? []);
  }

  Future<void> changePermission(String taskId, String shareId, String permission) async {
    await _api.patch('/tasks/$taskId/shares/$shareId', {'permission': permission});
  }

  Future<void> removeShare(String taskId, String shareId) async {
    await _api.delete('/tasks/$taskId/shares/$shareId');
  }
}