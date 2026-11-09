import 'package:flutter/material.dart';
import '../../models/task_share.dart';
import '../../services/api_client.dart';
import '../../services/task_share_service.dart';
import '../../widgets/user_selector.dart';

class TaskSharingScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final bool canManage;

  const TaskSharingScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.canManage,
  });

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen>
    with SingleTickerProviderStateMixin {
  final _service = TaskShareService();
  late final TabController _tab;

  List<Person> _assignees = [];
  List<TaskShare> _shares = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _load() async {
    try {
      final a = await _service.listAssignees(widget.taskId);
      final s = await _service.listShares(widget.taskId);
      if (!mounted) return;
      setState(() {
        _assignees = a;
        _shares = s;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Không kết nối được máy chủ');
    }
  }

  Future<bool> _confirm(String title, String content, String okLabel) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(okLabel, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    return r == true;
  }

  // ----- Giao việc -----
  Future<void> _addAssignees() async {
    final r = await showDialog<UserSelectorResult>(
      context: context,
      builder: (_) => const UserSelectorDialog(title: 'Giao việc cho'),
    );
    if (r == null) return;
    await _run(() async {
      final notFound = await _service.addAssignees(widget.taskId, r.emails);
      _toast(notFound.isEmpty
          ? 'Đã giao việc'
          : 'Đã giao việc. Không tìm thấy tài khoản: ${notFound.join(', ')}');
    });
  }

  Future<void> _assigneeAction(Person p, String action) async {
    if (action == 'primary' || action == 'unprimary') {
      await _run(() => _service.setPrimary(widget.taskId, p.id, action == 'primary'));
    } else if (action == 'remove') {
      final ok = await _confirm('Hủy giao việc', 'Hủy giao việc cho ${p.fullName}?', 'Hủy giao');
      if (ok) await _run(() => _service.removeAssignee(widget.taskId, p.id));
    }
  }

  // ----- Chia sẻ -----
  Future<void> _addShares() async {
    final r = await showDialog<UserSelectorResult>(
      context: context,
      builder: (_) => const UserSelectorDialog(title: 'Chia sẻ cho', askPermission: true),
    );
    if (r == null) return;
    await _run(() async {
      final notFound = await _service.addShares(widget.taskId, r.emails, r.permission);
      _toast(notFound.isEmpty
          ? 'Đã chia sẻ'
          : 'Đã chia sẻ. Không tìm thấy tài khoản: ${notFound.join(', ')}');
    });
  }

  Future<void> _shareAction(TaskShare s, String action) async {
    if (action == 'viewer' || action == 'editor') {
      await _run(() => _service.changePermission(widget.taskId, s.id, action));
    } else if (action == 'remove') {
      final ok = await _confirm(
        'Thu hồi quyền',
        'Thu hồi quyền truy cập của ${s.user.fullName}?',
        'Thu hồi',
      );
      if (ok) await _run(() => _service.removeShare(widget.taskId, s.id));
    }
  }

  // ----- Giao diện -----
  Widget _avatar(String name) =>
      CircleAvatar(child: Text(name.isEmpty ? '?' : name[0].toUpperCase()));

  Widget _empty(String text) => ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.group_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Center(child: Text(text)),
        ],
      );

  Widget _assigneeList() {
    if (_assignees.isEmpty) return _empty('Chưa giao cho ai');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final p in _assignees)
          ListTile(
            leading: _avatar(p.fullName),
            title: Row(
              children: [
                Flexible(child: Text(p.fullName, overflow: TextOverflow.ellipsis)),
                if (p.isPrimary) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text('Phụ trách chính'),
                    avatar: Icon(Icons.star, size: 16, color: Colors.amber),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            subtitle: Text(p.email),
            trailing: widget.canManage
                ? PopupMenuButton<String>(
                    onSelected: (a) => _assigneeAction(p, a),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: p.isPrimary ? 'unprimary' : 'primary',
                        child: Text(p.isPrimary
                            ? 'Bỏ vai trò phụ trách chính'
                            : 'Đặt làm người phụ trách chính'),
                      ),
                      const PopupMenuItem(value: 'remove', child: Text('Hủy giao việc')),
                    ],
                  )
                : null,
          ),
      ],
    );
  }

  Widget _shareList() {
    if (_shares.isEmpty) return _empty('Chưa chia sẻ cho ai');
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final s in _shares)
          ListTile(
            leading: _avatar(s.user.fullName),
            title: Text(s.user.fullName),
            subtitle: Text(s.user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(label: Text(s.permissionLabel), visualDensity: VisualDensity.compact),
                if (widget.canManage)
                  PopupMenuButton<String>(
                    onSelected: (a) => _shareAction(s, a),
                    itemBuilder: (_) => [
                      if (s.permission != 'viewer')
                        const PopupMenuItem(value: 'viewer', child: Text('Đổi thành chỉ xem')),
                      if (s.permission != 'editor')
                        const PopupMenuItem(value: 'editor', child: Text('Đổi thành chỉnh sửa')),
                      const PopupMenuItem(value: 'remove', child: Text('Thu hồi quyền')),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onAssignTab = _tab.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskTitle, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Được giao (${_assignees.length})'),
            Tab(text: 'Chia sẻ (${_shares.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: TabBarView(
                        controller: _tab,
                        children: [_assigneeList(), _shareList()],
                      ),
                    ),
                  ),
                ),
      floatingActionButton: widget.canManage && !_loading && _error == null
          ? FloatingActionButton.extended(
              onPressed: onAssignTab ? _addAssignees : _addShares,
              icon: Icon(onAssignTab ? Icons.person_add_alt_1 : Icons.share),
              label: Text(onAssignTab ? 'Giao việc' : 'Chia sẻ'),
            )
          : null,
    );
  }
}