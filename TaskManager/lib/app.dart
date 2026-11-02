import 'package:flutter/material.dart';
import 'services/api_client.dart';

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const ConnectionCheckScreen(),
    );
  }
}

class ConnectionCheckScreen extends StatefulWidget {
  const ConnectionCheckScreen({super.key});

  @override
  State<ConnectionCheckScreen> createState() => _ConnectionCheckScreenState();
}

class _ConnectionCheckScreenState extends State<ConnectionCheckScreen> {
  String _message = 'Dang kiem tra ket noi...';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final data = await ApiClient().get('/health');
      setState(() => _message = 'API: ${data['status']} | MongoDB: ${data['database']}');
    } catch (e) {
      setState(() => _message = 'Loi ket noi API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Manager')),
      body: Center(child: Text(_message)),
    );
  }
}