import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_activity.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/status_badge.dart';

class TaskActivityScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskActivityScreen({super.key, required this.taskId, required this.taskTitle});

  @override
  State<TaskActivityScreen> createState() => _TaskActivityScreenState();
}

class _TaskActivityScreenState extends State<TaskActivityScreen> {
  final _service = TaskService();
  final _fmt = DateFormat('HH:mm dd/MM/yyyy');
  late Future<List<TaskActivity>> _future;

  static const _fieldLabels = {
    'title': 'tên công việc',
    'description': 'mô tả',
    'priority': 'mức ưu tiên',
    'startDate': 'ngày bắt đầu',
    'dueDate': 'hạn hoàn thành',
  };

  @override
  void initState() {
    super.initState();
    _future = _service.activities(widget.taskId);
  }

  Future<void> _refresh() async {
    final f = _service.activities(widget.taskId);
    setState(() => _future = f);
    await f.catchError((_) => <TaskActivity>[]);
  }

  String _list(dynamic v) => (v is List ? v.map((e) => e.toString()).join(', ') : '');

  String _text(TaskActivity a) {
    final d = a.details;
    final perm = d['permission'] == 'editor' ? 'chỉnh sửa' : 'chỉ xem';
    switch (a.action) {
      case 'task_created':
        return 'đã tạo công việc';
      case 'task_updated':
        final fields = (d['fields'] is List ? d['fields'] as List : [])
            .map((e) => _fieldLabels[e] ?? e.toString())
            .join(', ');
        return 'đã chỉnh sửa $fields';
      case 'status_changed':
        return 'đã đổi trạng thái từ "${StatusBadge.label('${d['from']}')}" '
            'sang "${StatusBadge.label('${d['to']}')}"';
      case 'task_assigned':
        return 'đã giao việc cho ${_list(d['users'])}';
      case 'assignee_removed':
        return 'đã hủy giao việc của ${d['userName']}';
      case 'primary_set':
        return 'đã đặt ${d['userName']} làm người phụ trách chính';
      case 'primary_unset':
        return 'đã bỏ vai trò phụ trách chính của ${d['userName']}';
      case 'task_shared':
        return 'đã chia sẻ cho ${_list(d['users'])} (quyền $perm)';
      case 'share_permission_changed':
        return 'đã đổi quyền của ${d['userName']} thành $perm';
      case 'share_revoked':
        return 'đã thu hồi quyền của ${d['userName']}';
      default:
        return a.action;
    }
  }

  IconData _icon(String action) {
    switch (action) {
      case 'task_created':
        return Icons.add_circle_outline;
      case 'task_updated':
        return Icons.edit_outlined;
      case 'status_changed':
        return Icons.flag_outlined;
      case 'task_assigned':
      case 'assignee_removed':
        return Icons.assignment_ind_outlined;
      case 'primary_set':
      case 'primary_unset':
        return Icons.star_outline;
      default:
        return Icons.share_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hoạt động')),
      body: FutureBuilder<List<TaskActivity>>(
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
            return const Center(child: Text('Chưa có hoạt động nào'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: scheme.outlineVariant),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(_icon(a.action), color: scheme.onPrimaryContainer),
                        ),
                        title: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: a.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' ${_text(a)}'),
                            ],
                          ),
                        ),
                        subtitle: a.createdAt == null ? null : Text(_fmt.format(a.createdAt!)),
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