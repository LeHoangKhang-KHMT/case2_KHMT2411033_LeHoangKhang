import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/validators.dart';

class TaskEditScreen extends StatefulWidget {
  final Task task;
  const TaskEditScreen({super.key, required this.task});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _service = TaskService();
  final _fmt = DateFormat('dd/MM/yyyy');

  late String _priority;
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t.title);
    _descCtrl = TextEditingController(text: t.description);
    _priority = t.priority;
    _startDate = t.startDate;
    _dueDate = t.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _dueDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _dueDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      setState(() => _error = 'Hạn hoàn thành phải sau ngày bắt đầu');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _service.updateTask(
        widget.task.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
        startDate: _startDate,
        dueDate: _dueDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: value == null
              ? null
              : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ),
        child: Text(value == null ? 'Chọn ngày' : _fmt.format(value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa công việc')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên công việc',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => Validators.required(v, 'Tên công việc'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Mức độ ưu tiên', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'low', label: Text('Thấp')),
                      ButtonSegment(value: 'medium', label: Text('Trung bình')),
                      ButtonSegment(value: 'high', label: Text('Cao')),
                    ],
                    selected: {_priority},
                    onSelectionChanged: (s) => setState(() => _priority = s.first),
                  ),
                  const SizedBox(height: 20),
                  _dateField(
                    label: 'Ngày bắt đầu',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                    onClear: () => setState(() => _startDate = null),
                  ),
                  const SizedBox(height: 16),
                  _dateField(
                    label: 'Hạn hoàn thành',
                    value: _dueDate,
                    onTap: () => _pickDate(isStart: false),
                    onClear: () => setState(() => _dueDate = null),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu thay đổi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}