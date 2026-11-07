import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _auth = AuthService();

  User? _user;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _auth.getMe();
      setState(() {
        _user = user;
        _nameCtrl.text = user.fullName;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = await _auth.updateMe(fullName: _nameCtrl.text.trim());
      if (!mounted) return;
      setState(() => _user = user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin cá nhân')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text(_error ?? 'Không tải được thông tin'))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: scheme.primary,
                                child: Text(
                                  _user!.fullName.isNotEmpty
                                      ? _user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(fontSize: 32, color: scheme.onPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              initialValue: _user!.email,
                              enabled: false,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Họ tên',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) => Validators.required(v, 'Họ tên'),
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
                              onPressed: _saving ? null : _save,
                              child: _saving
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