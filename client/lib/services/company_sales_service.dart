import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';

class CompanySalesService {
  CompanySalesService._();

  static final CompanySalesService instance = CompanySalesService._();

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
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/stats');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['stats'] as Map);
      }
    }
    throw Exception('Failed to fetch CSA stats');
  }

  Future<Map<String, dynamic>> getShops({String? status, int page = 1}) async {
    final query = <String, String>{'page': page.toString(), 'limit': '20'};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/shops')
        .replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
    }
    throw Exception('Failed to fetch CSA shops');
  }

  Future<Map<String, dynamic>> getReports({String? month}) async {
    final query = <String, String>{};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/reports')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
    }
    throw Exception('Failed to fetch CSA reports');
  }
}

