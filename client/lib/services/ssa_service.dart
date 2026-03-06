import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';
import '../models/ssa_lead_model.dart';

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

  Future<List<SsaLead>> getLeads() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ssa/leads');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final list = (data['leads'] as List<dynamic>? ?? []);
        return list
            .map((e) => SsaLead.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw Exception('Failed to fetch SSA leads');
  }

  Future<List<Map<String, dynamic>>> getCoupons() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ssa/coupons');
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
    throw Exception('Failed to fetch SSA coupons');
  }

  Future<SsaLead> createLead({
    required String shopName,
    required String phone,
    String? ownerName,
    String? pincode,
    String? city,
    String? category,
    String? notes,
    String? couponCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/ssa/leads');
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
    };

    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return SsaLead.fromJson(data['lead'] as Map<String, dynamic>);
    }

    final message = data['message']?.toString() ?? 'Failed to create lead';
    throw Exception(message);
  }
}
