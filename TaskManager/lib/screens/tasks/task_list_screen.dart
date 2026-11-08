import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/token_storage.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/task_card.dart';
import '../auth/login_screen.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int _version = 0;

  static const _tabs = [
    ('all', 'Tất cả'),
    ('created', 'Tôi tạo'),
    ('assigned', 'Được giao'),
    ('shared', 'Được chia sẻ'),
  ];

  void _reload() => setState(() => _version++);

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
    );
    if (created == true && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo công việc thành công')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công việc'),
          actions: [
            IconButton(
              tooltip: 'Thông tin cá nhân',
              icon: const Icon(Icons.person_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in _tabs) Tab(text: t.$2)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final t in _tabs)
              _TaskListView(key: ValueKey('${t.$1}-$_version'), scope: t.$1),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text('Tạo công việc'),
        ),
      ),
    );
  }
}

class _TaskListView extends StatefulWidget {
  final String scope;
  const _TaskListView({super.key, required this.scope});

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView> {
  final _service = TaskService();
  late Future<List<Task>> _future;

  static const _emptyText = {
    'all': 'Bạn chưa có công việc nào.\nBấm "Tạo công việc" để bắt đầu.',
    'created': 'Bạn chưa tạo công việc nào.',
    'assigned': 'Chưa có công việc nào được giao cho bạn.',
    'shared': 'Chưa có công việc nào được chia sẻ với bạn.',
  };

  @override
  void initState() {
    super.initState();
    _future = _service.listTasks(scope: widget.scope);
  }

  Future<void> _refresh() async {
    final f = _service.listTasks(scope: widget.scope);
    setState(() => _future = f);
    await f.catchError((_) => <Task>[]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
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
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(msg),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _refresh, child: const Text('Thử lại')),
              ],
            ),
          );
        }

        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          final scheme = Theme.of(context).colorScheme;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.inbox_outlined,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _emptyText[widget.scope] ?? 'Chưa có công việc nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: tasks.length + 1,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: i == 0
                    ? _SummaryRow(tasks: tasks)
                      : TaskCard(
                        task: tasks[i - 1],
                        onTap: () async {
                          final result = await Navigator.of(context).push<String>(
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(taskId: tasks[i - 1].id),
                            ),
                          );
                          if (!mounted) return;
                          _refresh();
                          if (result == 'deleted') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa công việc')),
                            );
                          }
                        },
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<Task> tasks;
  const _SummaryRow({required this.tasks});

  Widget _item(String status, int count) {
    final c = StatusBadge.color(status);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c),
            ),
            const SizedBox(height: 2),
            Text(
              StatusBadge.label(status),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int n(String s) => tasks.where((t) => t.status == s).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          _item('todo', n('todo')),
          _item('in_progress', n('in_progress')),
          _item('completed', n('completed')),
        ],
      ),
    );
  }
}