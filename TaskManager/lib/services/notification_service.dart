import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<AppNotification>> list() async {
    final data = await _api.get('/notifications');
    return (data['notifications'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final data = await _api.get('/notifications/unread-count');
    return (data['count'] as num).toInt();
  }

  Future<void> markRead(String id) async {
    await _api.patch('/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    await _api.patch('/notifications/read-all', {});
  }
}