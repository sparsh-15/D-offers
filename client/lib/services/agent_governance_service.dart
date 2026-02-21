import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_store.dart';

class AgentGovernanceService {
  static final AgentGovernanceService instance = AgentGovernanceService._();
  AgentGovernanceService._();

  Future<Map<String, dynamic>> getDashboard() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch dashboard');
    }
  }

  Future<Map<String, dynamic>> getSSAList({
    String? search,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/agent-governance/ssa')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch SSA list');
    }
  }

  Future<Map<String, dynamic>> getCompanySalesAgentList({
    String? search,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isActive != null) queryParams['isActive'] = isActive.toString();

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/agent-governance/company-sales-agents')
            .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Failed to fetch company sales agent list');
    }
  }

  Future<Map<String, dynamic>> getCouponActivations({
    String? couponCode,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (couponCode != null && couponCode.isNotEmpty) {
      queryParams['couponCode'] = couponCode;
    }
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }

    final uri =
        Uri.parse('${ApiConfig.baseUrl}/agent-governance/coupons/activations')
            .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to fetch coupon activations');
    }
  }
}
