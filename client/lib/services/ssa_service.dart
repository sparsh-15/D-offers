import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';

class SsaService {
  SsaService._();

  static final SsaService instance = SsaService._();

  final http.Client _client = http.Client();

  Map<String, String> _headers() {
    final token = AuthStore.token;
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getStats() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ssa/stats');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['stats'] as Map? ?? {});
      }
    }
    throw Exception('Failed to fetch SSA stats');
  }

  Future<List<dynamic>> getShopkeepers() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ssa/shopkeepers');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return List<dynamic>.from(data['shopkeepers'] as List? ?? []);
      }
    }
    throw Exception('Failed to fetch assigned shopkeepers');
  }
}
