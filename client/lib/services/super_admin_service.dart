import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_store.dart';

class SuperAdminService {
  static final SuperAdminService instance = SuperAdminService._();
  SuperAdminService._();

  Future<Map<String, dynamic>> getDashboardAnalytics() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/super-admin/analytics'),
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
      throw Exception(error['message'] ?? 'Failed to fetch analytics');
    }
  }

  Future<Map<String, dynamic>> getAllUsers({
    String? role,
    bool? isActive,
    String? approvalStatus,
    String? pincode,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (role != null) queryParams['role'] = role;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    if (approvalStatus != null) queryParams['approvalStatus'] = approvalStatus;
    if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/users')
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
      throw Exception(error['message'] ?? 'Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> getAllShops({
    String? subscriptionStatus,
    String? pincode,
    String? city,
    String? category,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (subscriptionStatus != null) {
      queryParams['subscriptionStatus'] = subscriptionStatus;
    }
    if (pincode != null && pincode.isNotEmpty) queryParams['pincode'] = pincode;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/shops')
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
      throw Exception(error['message'] ?? 'Failed to fetch shops');
    }
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isActive': isActive}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update user status');
    }
  }

  Future<void> updateApprovalStatus(
      String userId, String approvalStatus) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId/approval'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'approvalStatus': approvalStatus}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to update approval status');
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$userId'),
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
      throw Exception(error['message'] ?? 'Failed to fetch user details');
    }
  }

  Future<Map<String, dynamic>> getAuditLogs({
    String? action,
    String? adminId,
    String? targetUserId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (action != null) queryParams['action'] = action;
    if (adminId != null) queryParams['adminId'] = adminId;
    if (targetUserId != null) queryParams['targetUserId'] = targetUserId;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final uri = Uri.parse('${ApiConfig.baseUrl}/super-admin/audit-logs')
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
      throw Exception(error['message'] ?? 'Failed to fetch audit logs');
    }
  }
}
