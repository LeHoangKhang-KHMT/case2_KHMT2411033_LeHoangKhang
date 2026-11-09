import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task_share.dart';
import '../services/user_service.dart';

class UserSelectorResult {
  final List<String> emails;
  final String permission;
  UserSelectorResult(this.emails, this.permission);
}

class UserSelectorDialog extends StatefulWidget {
  final String title;
  final bool askPermission;

  const UserSelectorDialog({
    super.key,
    required this.title,
    this.askPermission = false,
  });

  @override
  State<UserSelectorDialog> createState() => _UserSelectorDialogState();
}

class _UserSelectorDialogState extends State<UserSelectorDialog> {
  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _ctrl = TextEditingController();
  final _service = UserService();
  Timer? _debounce;

  List<Person> _results = [];
  bool _searching = false;
  String _query = '';
  String _permission = 'viewer';
  final Map<String, String> _selected = {}; // email -> tên hiển thị

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    final q = v.trim();
    setState(() => _query = q);
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final r = await _service.search(q);
        if (mounted && _query == q) setState(() => _results = r);
      } catch (_) {
        if (mounted) setState(() => _results = []);
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _toggle(String email, String label) {
    setState(() {
      if (_selected.containsKey(email)) {
        _selected.remove(email);
      } else {
        _selected[email] = label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lower = _query.toLowerCase();
    final canAddRaw = _emailRe.hasMatch(_query) &&
        !_results.any((p) => p.email.toLowerCase() == lower) &&
        !_selected.containsKey(lower);

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Nhập tên hoặc email',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            if (_selected.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final e in _selected.entries)
                    InputChip(
                      label: Text(e.value),
                      onDeleted: () => _toggle(e.key, e.value),
                    ),
                ],
              ),
            ],
            if (widget.askPermission) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'viewer', label: Text('Chỉ xem')),
                  ButtonSegment(value: 'editor', label: Text('Chỉnh sửa')),
                ],
                selected: {_permission},
                onSelectionChanged: (s) => setState(() => _permission = s.first),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_searching) const LinearProgressIndicator(),
                    if (canAddRaw)
                      ListTile(
                        leading: const Icon(Icons.alternate_email),
                        title: Text('Thêm theo email: $_query'),
                        onTap: () => _toggle(lower, lower),
                      ),
                    for (final p in _results)
                      ListTile(
                        leading: CircleAvatar(
                          child: Text(p.fullName.isEmpty ? '?' : p.fullName[0].toUpperCase()),
                        ),
                        title: Text(p.fullName),
                        subtitle: Text(p.email),
                        trailing: Icon(
                          _selected.containsKey(p.email.toLowerCase())
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _selected.containsKey(p.email.toLowerCase())
                              ? scheme.primary
                              : null,
                        ),
                        onTap: () => _toggle(p.email.toLowerCase(), p.fullName),
                      ),
                    if (!_searching && _query.length >= 2 && _results.isEmpty && !canAddRaw)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Không tìm thấy người dùng',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                    UserSelectorResult(_selected.keys.toList(), _permission),
                  ),
          child: Text('Thêm (${_selected.length})'),
        ),
      ],
    );
  }
}