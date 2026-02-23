import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'storage_service.dart';

class ApiClient {
  ApiClient(this._storage);

  final StorageService _storage;

  Future<http.Response> get(String path, {bool auth = true}) {
    return _send('GET', path, auth: auth);
  }

  Future<http.Response> post(String path, Map<String, dynamic> body,
      {bool auth = true}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<http.Response> put(String path, Map<String, dynamic> body,
      {bool auth = true}) {
    return _send('PUT', path, body: body, auth: auth);
  }

  Future<http.Response> delete(String path, {bool auth = true}) {
    return _send('DELETE', path, auth: auth);
  }

  dynamic decodeJson(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<')) {
      throw FormatException('Response is not JSON. Check API_BASE_URL.');
    }
    return jsonDecode(body);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (auth) {
      final token = _storage.loadAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'PUT':
        return http.put(uri, headers: headers, body: jsonEncode(body ?? {}));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }
}
