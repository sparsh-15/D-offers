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

  Map<String, dynamic> _decodeJson(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Never _throwApiError(http.Response response, String fallbackMessage) {
    final data = _decodeJson(response);
    final message = data['message']?.toString();
    throw Exception(message ?? fallbackMessage);
  }

  Future<Map<String, dynamic>> getStats() async {
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/stats');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = _decodeJson(response);
      if (data['success'] == true && data['stats'] is Map) {
        return Map<String, dynamic>.from(data['stats'] as Map);
      }
      _throwApiError(response, 'Failed to fetch CSA stats');
    }
    _throwApiError(response, 'Failed to fetch CSA stats');
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
      final data = _decodeJson(response);
      if (data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      _throwApiError(response, 'Failed to fetch CSA shops');
    }
    _throwApiError(response, 'Failed to fetch CSA shops');
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
      final data = _decodeJson(response);
      if (data['success'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      _throwApiError(response, 'Failed to fetch CSA reports');
    }
    _throwApiError(response, 'Failed to fetch CSA reports');
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/coupons');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = _decodeJson(response);
      if (data['success'] == true) {
        final list = (data['coupons'] as List<dynamic>? ?? []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      _throwApiError(response, 'Failed to fetch CSA coupons');
    }
    _throwApiError(response, 'Failed to fetch CSA coupons');
  }

  Future<List<Map<String, dynamic>>> getLeads(
      {String? status, String? search}) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/leads')
        .replace(queryParameters: query.isEmpty ? null : query);
    final response = await _client.get(uri, headers: _headers());
    if (response.statusCode == 200) {
      final data = _decodeJson(response);
      if (data['success'] == true) {
        final list = (data['leads'] as List<dynamic>? ?? []);
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      _throwApiError(response, 'Failed to fetch leads');
    }
    _throwApiError(response, 'Failed to fetch leads');
  }

  Future<Map<String, dynamic>> createLead({
    required String shopName,
    required String phone,
    String? ownerName,
    String? pincode,
    String? city,
    String? category,
    String? notes,
    String? couponCode,
    String? address,
    String? description,
  }) async {
    final uri = Uri.parse('${ApiConfig.companySalesUrl}/leads');
    final body = <String, dynamic>{
      'shopName': shopName,
      'phone': phone,
      if (ownerName != null && ownerName.trim().isNotEmpty)
        'ownerName': ownerName.trim(),
      if (pincode != null && pincode.trim().isNotEmpty)
        'pincode': pincode.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (couponCode != null && couponCode.trim().isNotEmpty)
        'couponCode': couponCode.trim(),
      if (address != null && address.trim().isNotEmpty)
        'address': address.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    final data = _decodeJson(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return Map<String, dynamic>.from(data['lead'] as Map);
    }
    final owner = data['owner'] as Map<String, dynamic>?;
    final ownerMsg = owner == null
        ? ''
        : ' (Owner: ${owner['ownerAgentRole'] ?? 'agent'}, status: ${owner['status'] ?? 'unknown'})';
    throw Exception(
        '${data['message']?.toString() ?? 'Failed to create lead'}$ownerMsg');
  }

  Future<Map<String, dynamic>> retryLeadInvite(String leadId) async {
    final uri =
        Uri.parse('${ApiConfig.companySalesUrl}/leads/$leadId/retry-invite');
    final response = await _client.post(uri, headers: _headers());
    final data = _decodeJson(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return Map<String, dynamic>.from(data['lead'] as Map);
    }
    throw Exception(data['message']?.toString() ?? 'Failed to retry invite');
  }
}
