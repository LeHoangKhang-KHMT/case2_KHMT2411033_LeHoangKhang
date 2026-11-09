import '../models/task_share.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _api = ApiClient();

  Future<List<Person>> search(String q) async {
    final data = await _api.get('/users/search?q=${Uri.encodeQueryComponent(q)}');
    final list = data['users'] as List<dynamic>;
    return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
  }
}