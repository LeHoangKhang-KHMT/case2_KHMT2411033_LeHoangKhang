import '../utils/token_storage.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _api.post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<String> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', {'email': email, 'password': password});
    final user = data['user'] as Map<String, dynamic>;
    final fullName = user['fullName'] as String;
    await TokenStorage.save(data['token'] as String, fullName);
    return fullName;
  }
}