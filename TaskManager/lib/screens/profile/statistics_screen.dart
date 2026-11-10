import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_client.dart';
import '../../services/statistics_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../tasks/task_detail_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _Data {
  final Map<String, dynamic> tasks;
  final Map<String, dynamic> assignments;
  final Map<String, dynamic> deadlines;
  _Data(this.tasks, this.assignments, this.deadlines);
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _service = StatisticsService();
  late Future<_Data> _future;

  static const _statuses = ['todo', 'in_progress', 'completed'];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Data> _load() async {
    final t = await _service.tasks();
    final a = await _service.assignments();
    final d = await _service.deadlines();
    return _Data(t, a, d);
  }

  Future<void> _refresh() async {
    final f = _load();
    setState(() => _future = f);
    await f.catchError((_) => _Data({}, {}, {}));
  }

  int _i(dynamic map, String key) =>
      map is Map ? ((map[key] as num?)?.toInt() ?? 0) : 0;

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _card(Widget child) => Card(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      );

  // ----- Theo trạng thái -----
  Widget _statusSection(Map<String, dynamic> t) {
    final byStatus = t['byStatus'];
    final total = _i(t, 'total');

    return _section(
      'Công việc theo trạng thái',
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tổng cộng: $total công việc',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: total == 0
                    ? Container(color: Colors.grey.shade300)
                    : Row(
                        children: [
                          for (final s in _statuses)
                            if (_i(byStatus, s) > 0)
                              Expanded(
                                flex: _i(byStatus, s),
                                child: Container(color: StatusBadge.color(s)),
                              ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final s in _statuses)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: StatusBadge.color(s).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text('${_i(byStatus, s)}',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: StatusBadge.color(s))),
                          Text(StatusBadge.label(s),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: StatusBadge.color(s))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final p in ['high', 'medium', 'low'])
                  Chip(
                    label: Text('${PriorityBadge.label(p)}: ${_i(t['byPriority'], p)}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----- Được giao, phụ trách, đã tạo -----
  Widget _assignCard(String title, IconData icon, dynamic m) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 8),
            Text('${_i(m, 'total')}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 8),
            Text('${_i(m, 'in_progress')} đang làm', style: const TextStyle(fontSize: 12)),
            Text('${_i(m, 'completed')} hoàn thành', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _assignSection(Map<String, dynamic> a) {
    return _section(
      'Giao việc và phụ trách',
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _assignCard('Được giao cho tôi', Icons.assignment_ind_outlined, a['assigned']),
          const SizedBox(width: 8),
          _assignCard('Tôi phụ trách', Icons.star_outline, a['primary']),
          const SizedBox(width: 8),
          _assignCard('Tôi đã tạo', Icons.edit_note, a['created']),
        ],
      ),
    );
  }

  // ----- Hạn hoàn thành -----
  Widget _taskTile(Map<String, dynamic> t, {required bool overdue}) {
    final fmt = DateFormat('dd/MM/yyyy');
    final due = t['dueDate'] == null ? null : DateTime.parse(t['dueDate'] as String).toLocal();
    final color = overdue ? Theme.of(context).colorScheme.error : Colors.orange.shade800;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(overdue ? Icons.warning_amber_rounded : Icons.schedule, color: color),
      title: Text(t['title'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(due == null ? '' : 'Hạn: ${fmt.format(due)}', style: TextStyle(color: color)),
      trailing: PriorityBadge(priority: (t['priority'] ?? 'medium') as String),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['_id'].toString())),
      ),
    );
  }

  Widget _deadlineBlock(String title, int count, List list, {required bool overdue, required String empty}) {
    final color = overdue ? Theme.of(context).colorScheme.error : Colors.orange.shade800;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
            const SizedBox(width: 8),
            Chip(label: Text('$count'), visualDensity: VisualDensity.compact),
          ],
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(empty, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          )
        else
          for (final t in list) _taskTile(t as Map<String, dynamic>, overdue: overdue),
      ],
    );
  }

  Widget _deadlineSection(Map<String, dynamic> d) {
    return _section(
      'Hạn hoàn thành',
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _deadlineBlock('Đã quá hạn', _i(d, 'overdueCount'), (d['overdue'] ?? []) as List,
                overdue: true, empty: 'Không có công việc quá hạn'),
            const Divider(height: 24),
            _deadlineBlock('Sắp đến hạn (7 ngày tới)', _i(d, 'dueSoonCount'),
                (d['dueSoon'] ?? []) as List,
                overdue: false, empty: 'Không có công việc sắp đến hạn'),
            const SizedBox(height: 8),
            Text('${_i(d, 'noDueCount')} công việc chưa đặt hạn',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: FutureBuilder<_Data>(
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

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      children: [
                        _statusSection(data.tasks),
                        _assignSection(data.assignments),
                        _deadlineSection(data.deadlines),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}