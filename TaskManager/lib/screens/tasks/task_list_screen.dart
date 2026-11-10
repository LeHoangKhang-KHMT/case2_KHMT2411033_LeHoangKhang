import 'dart:async';
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
import '../../services/notification_service.dart';
import '../notifications/notification_screen.dart';
import '../profile/statistics_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  int _version = 0;
  String _query = '';
  String? _status;
  String? _priority;
  String _sort = 'createdAt:desc';
  Timer? _debounce;
  Timer? _poll;
  int _unread = 0;
  final _notifService = NotificationService();
  final _searchCtrl = TextEditingController();

  static const _tabs = [
    ('all', 'Tất cả'),
    ('created', 'Tôi tạo'),
    ('primary', 'Tôi phụ trách'),
    ('assigned', 'Được giao'),
    ('shared', 'Được chia sẻ'),
  ];

  static const _statusOptions = {
    '': 'Tất cả trạng thái',
    'todo': 'Chưa thực hiện',
    'in_progress': 'Đang thực hiện',
    'completed': 'Đã hoàn thành',
  };

  static const _priorityOptions = {
    '': 'Mọi mức ưu tiên',
    'low': 'Thấp',
    'medium': 'Trung bình',
    'high': 'Cao',
  };

  static const _sortOptions = {
    'createdAt:desc': 'Mới tạo nhất',
    'createdAt:asc': 'Cũ nhất',
    'dueDate:asc': 'Hạn gần nhất',
    'dueDate:desc': 'Hạn xa nhất',
    'priority:desc': 'Ưu tiên cao trước',
    'priority:asc': 'Ưu tiên thấp trước',
  };

  @override
  void initState() {
    super.initState();
    _loadUnread();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _loadUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUnread() async {
    try {
      final n = await _notifService.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {}
  }

  void _reload() => setState(() => _version++);

  void _onSearchChanged(String v) {
    setState(() {}); // cập nhật nút xóa trong ô tìm kiếm
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _status = null;
      _priority = null;
    });
  }

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

  List<PopupMenuEntry<String>> _menuItems(Map<String, String> options, String current) => [
        for (final e in options.entries)
          CheckedPopupMenuItem<String>(
            value: e.key,
            checked: e.key == current,
            child: Text(e.value),
          ),
      ];

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool active,
    required Map<String, String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => _menuItems(options, current),
      child: Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        backgroundColor: active ? scheme.primaryContainer : Colors.white,
        side: BorderSide(color: active ? scheme.primary : scheme.outlineVariant),
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasFilter = _status != null || _priority != null || _query.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên công việc',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(
                      icon: Icons.flag_outlined,
                      label: _status == null ? 'Trạng thái' : _statusOptions[_status]!,
                      active: _status != null,
                      options: _statusOptions,
                      current: _status ?? '',
                      onSelected: (v) => setState(() => _status = v.isEmpty ? null : v),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      icon: Icons.priority_high,
                      label: _priority == null ? 'Ưu tiên' : _priorityOptions[_priority]!,
                      active: _priority != null,
                      options: _priorityOptions,
                      current: _priority ?? '',
                      onSelected: (v) =>
                          setState(() => _priority = v.isEmpty ? null : v),
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      icon: Icons.sort,
                      label: _sortOptions[_sort]!,
                      active: _sort != 'createdAt:desc',
                      options: _sortOptions,
                      current: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                    ),
                    if (hasFilter) ...[
                      const SizedBox(width: 8),
                      TextButton(onPressed: _clearFilters, child: const Text('Xóa lọc')),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortParts = _sort.split(':');
    final filtered = _status != null || _priority != null || _query.isNotEmpty;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Công việc'),
          actions: [
            IconButton(
              tooltip: 'Thống kê',
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Thông báo',
              icon: Badge.count(
                count: _unread,
                isLabelVisible: _unread > 0,
                child: const Icon(Icons.notifications_outlined),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
                _loadUnread();
              },
            ),
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
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: TabBarView(
                children: [
                  for (final t in _tabs)
                    _TaskListView(
                      key: ValueKey(
                        '${t.$1}-$_version-$_query-$_status-$_priority-$_sort',
                      ),
                      scope: t.$1,
                      query: _query,
                      status: _status,
                      priority: _priority,
                      sortBy: sortParts[0],
                      order: sortParts[1],
                      filtered: filtered,
                    ),
                ],
              ),
            ),
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
  final String query;
  final String? status;
  final String? priority;
  final String sortBy;
  final String order;
  final bool filtered;

  const _TaskListView({
    super.key,
    required this.scope,
    required this.query,
    required this.status,
    required this.priority,
    required this.sortBy,
    required this.order,
    required this.filtered,
  });

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
    'primary': 'Bạn chưa phụ trách công việc nào.',
  };

  Future<List<Task>> _fetch() => _service.listTasks(
        scope: widget.scope,
        q: widget.query,
        status: widget.status,
        priority: widget.priority,
        sortBy: widget.sortBy,
        order: widget.order,
      );

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<void> _refresh() async {
    final f = _fetch();
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
                const SizedBox(height: 60),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      widget.filtered ? Icons.search_off : Icons.inbox_outlined,
                      size: 40,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.filtered
                      ? 'Không có công việc phù hợp với bộ lọc.'
                      : (_emptyText[widget.scope] ?? 'Chưa có công việc nào'),
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
                          if (!mounted || !context.mounted) return;
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
          color: c.withValues(alpha: 0.12),
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