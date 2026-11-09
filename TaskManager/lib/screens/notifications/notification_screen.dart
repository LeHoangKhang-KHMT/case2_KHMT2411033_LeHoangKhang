import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  final _fmt = DateFormat('HH:mm dd/MM/yyyy');
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.list();
  }

  Future<void> _refresh() async {
    final f = _service.list();
    setState(() => _future = f);
    await f.catchError((_) => <AppNotification>[]);
  }

  Future<void> _markAll() async {
    try {
      await _service.markAllRead();
    } catch (_) {}
    if (mounted) _refresh();
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _service.markRead(n.id);
      } catch (_) {}
    }
    if (n.taskId != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: n.taskId!)),
      );
    }
    if (mounted) _refresh();
  }

  IconData _icon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_outlined;
      case 'task_shared':
        return Icons.share_outlined;
      case 'due_date_changed':
        return Icons.event_repeat;
      case 'task_completed':
        return Icons.check_circle_outline;
      case 'due_soon':
        return Icons.alarm;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton.icon(
            onPressed: _markAll,
            icon: const Icon(Icons.done_all),
            label: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final msg = err is ApiException ? err.message : 'Không kết nối được máy chủ';
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(msg),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _refresh, child: const Text('Thử lại')),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Chưa có thông báo nào')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Card(
                      elevation: 0,
                      color: n.isRead ? Colors.white : scheme.primaryContainer.withValues(alpha: 0.35),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        onTap: () => _open(n),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(_icon(n.type), color: scheme.onPrimaryContainer),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.message),
                            if (n.createdAt != null)
                              Text(
                                _fmt.format(n.createdAt!),
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                        trailing: n.isRead
                            ? null
                            : Icon(Icons.circle, size: 10, color: scheme.primary),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}