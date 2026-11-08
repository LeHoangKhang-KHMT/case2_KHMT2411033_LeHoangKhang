import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskService();
  late Future<TaskDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getTask(widget.taskId);
  }

  void _reload() {
    setState(() => _future = _service.getTask(widget.taskId));
  }

  Future<void> _edit(Task task) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
    if (updated == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật công việc thành công')),
      );
    }
  }

  Future<void> _delete(Task task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn có chắc muốn xóa "${task.title}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Xóa',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _service.deleteTask(task.id);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không kết nối được máy chủ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TaskDetail>(
      future: _future,
      builder: (context, snapshot) {
        final detail = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết công việc'),
            actions: [
              if (detail != null && detail.access.canEdit)
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(detail.task),
                ),
              if (detail != null && detail.access.canDelete)
                IconButton(
                  tooltip: 'Xóa',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(detail.task),
                ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                final err = snapshot.error;
                final msg =
                    err is ApiException ? err.message : 'Không kết nối được máy chủ';
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(msg),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _reload, child: const Text('Thử lại')),
                    ],
                  ),
                );
              }

              return _DetailBody(task: detail!.task, access: detail.access);
            },
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  final Task task;
  final TaskAccess access;

  const _DetailBody({required this.task, required this.access});

  String _date(DateTime? d) =>
      d == null ? 'Chưa đặt' : DateFormat('dd/MM/yyyy').format(d);

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = task.status == 'completed';
    final assignees =
        task.assigneeNames.isEmpty ? 'Chưa giao cho ai' : task.assigneeNames.join(', ');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(status: task.status),
                      PriorityBadge(priority: task.priority),
                      Chip(
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                        label: Text(access.roleLabel),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Mô tả', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    task.description.isEmpty ? 'Không có mô tả' : task.description,
                    style: TextStyle(
                      color: task.description.isEmpty ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  const Divider(height: 32),
                  _row(context, Icons.person_outline, 'Người tạo',
                      task.createdByName ?? '—'),
                  _row(context, Icons.group_outlined, 'Người được giao', assignees),
                  _row(context, Icons.star_outline, 'Người phụ trách',
                      task.primaryAssigneeName ?? 'Chưa chỉ định'),
                  _row(context, Icons.play_circle_outline, 'Ngày bắt đầu',
                      _date(task.startDate)),
                  _row(context, Icons.event, 'Hạn hoàn thành', _date(task.dueDate)),
                  _row(context, Icons.schedule, 'Ngày tạo', _date(task.createdAt)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}