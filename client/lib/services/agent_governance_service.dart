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

  Future<Map<String, dynamic>> createCoupon({
    required String discountType,
    required num discountValue,
    required String agentId,
    String? description,
    DateTime? expiryDate,
    int? maxUses,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'discountType': discountType,
      'discountValue': discountValue,
      'agentId': agentId,
      if (description != null) 'description': description,
      if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
      if (maxUses != null) 'maxUses': maxUses,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/coupons'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create coupon');
    }
  }

  Future<Map<String, dynamic>> createSSA({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? state,
    String? region,
    String? pincode,
    int? maxCouponDiscountPercent,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'ssa',
      if (state != null) 'state': state,
      if (region != null) 'region': region,
      if (pincode != null) 'pincode': pincode,
      if (maxCouponDiscountPercent != null)
        'maxCouponDiscountPercent': maxCouponDiscountPercent,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/ssa'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to create SSA');
    }
  }

  Future<Map<String, dynamic>> createCompanySalesAgent({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? region,
    String? territory,
    String? pincode,
    String? workingHours,
    int? maxCouponDiscountPercent,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': 'company_sales_agent',
      if (region != null) 'region': region,
      if (territory != null) 'territory': territory,
      if (pincode != null) 'pincode': pincode,
      if (workingHours != null && workingHours.trim().isNotEmpty)
        'workingHours': workingHours.trim(),
      if (maxCouponDiscountPercent != null)
        'maxCouponDiscountPercent': maxCouponDiscountPercent,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/company-sales-agents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
          error['message'] ?? 'Failed to create company sales agent');
    }
  }

  Future<Map<String, dynamic>> getCouponList({
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

    final uri = Uri.parse('${ApiConfig.baseUrl}/agent-governance/coupons')
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
      throw Exception(error['message'] ?? 'Failed to fetch coupon list');
    }
  }

  Future<int> getCouponCap() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/settings/coupon-cap'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['maxCouponDiscountPercent'] != null) {
        return (data['maxCouponDiscountPercent'] as num).toInt();
      }
    }
    throw Exception('Failed to fetch coupon cap');
  }

  Future<int> updateCouponCap(int maxCouponDiscountPercent) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/agent-governance/settings/coupon-cap'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'maxCouponDiscountPercent': maxCouponDiscountPercent}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['maxCouponDiscountPercent'] != null) {
        return (data['maxCouponDiscountPercent'] as num).toInt();
      }
    }
    final error = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(error?['message'] ?? 'Failed to update coupon cap');
  }
}
