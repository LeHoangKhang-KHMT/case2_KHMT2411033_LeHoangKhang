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
}