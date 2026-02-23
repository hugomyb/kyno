import 'dart:convert';

import 'api_client.dart';
import 'api_exceptions.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/api/v1/login', {
      'email': email,
      'password': password,
    }, auth: false);

    if (response.statusCode == 401) {
      throw UnauthorizedException('Invalid credentials');
    }

    if (response.statusCode != 200) {
      throw ApiException('Login failed', response.statusCode);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return LoginResponse(
      token: payload['token'] as String,
      user: Map<String, dynamic>.from(payload['user'] as Map),
    );
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get('/api/v1/me');

    if (response.statusCode == 401) {
      throw UnauthorizedException('Unauthorized');
    }

    if (response.statusCode != 200) {
      throw ApiException('Failed to fetch user', response.statusCode);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(payload['user'] as Map);
  }

  Future<void> logout() async {
    final response = await _client.post('/api/v1/logout', {}, auth: true);
    if (response.statusCode == 401) {
      throw UnauthorizedException('Unauthorized');
    }

    if (response.statusCode != 200) {
      throw ApiException('Logout failed', response.statusCode);
    }
  }
}

class LoginResponse {
  LoginResponse({required this.token, required this.user});

  final String token;
  final Map<String, dynamic> user;
}
