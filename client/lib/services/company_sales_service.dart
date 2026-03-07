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

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/coupons');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['coupons'] as List<dynamic>? ?? []);
        return list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    throw Exception('Failed to fetch CSA coupons');
  }

  Future<List<Map<String, dynamic>>> getLeads({String? status, String? search}) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/leads')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['leads'] as List<dynamic>? ?? []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    throw Exception('Failed to fetch leads');
  }

  Future<void> createLead({
    required String shopName,
    required String phone,
    String? ownerName,
    String? pincode,
    String? city,
    String? category,
    String? notes,
    String? couponCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/leads');
    final body = <String, dynamic>{
      'shopName': shopName,
      'phone': phone,
      if (ownerName != null && ownerName.trim().isNotEmpty) 'ownerName': ownerName.trim(),
      if (pincode != null && pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (couponCode != null && couponCode.trim().isNotEmpty) 'couponCode': couponCode.trim(),
    };
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to create lead');
    }
  }
}

