import 'package:flutter/material.dart';
import '../../utils/token_storage.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    TokenStorage.readName().then((n) {
      if (mounted) setState(() => _name = n ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cong viec')),
      body: Center(child: Text('Xin chao, $_name')),
    );
  }
}