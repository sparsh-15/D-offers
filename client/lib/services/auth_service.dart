import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../models/user_model.dart';
import '../models/role_enum.dart';
import '../models/offer_model.dart';
import '../models/shopkeeper_profile_model.dart';
import 'auth_store.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final http.Client _client = http.Client();

  Future<void> signup({
    required UserRole role,
    required String phone,
    required String name,
    required String pincode,
    String? city,
    String? address,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/signup');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': roleToString(role),
        'phone': phone,
        'name': name,
        'pincode': pincode,
        'city': city ?? '',
        'address': address ?? '',
      }),
    );
    _handleResponse(resp);
  }

  Future<void> sendOtp({
    required UserRole role,
    required String phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/send-otp');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': roleToString(role),
        'phone': phone,
      }),
    );
    _handleResponse(resp);
  }

  Future<void> verifyOtp({
    required UserRole role,
    required String phone,
    required String otp,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/verify-otp');
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': roleToString(role),
        'phone': phone,
        'otp': otp,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null) {
      throw Exception('Token not returned from server');
    }
    AuthStore.token = token;
    // Fetch full user profile via /me so we get approvalStatus etc.
    AuthStore.currentUser = await fetchCurrentUser();
  }

  Future<UserModel> fetchCurrentUser() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.authUrl}/me');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  // Shopkeeper profile
  Future<ShopkeeperProfileModel?> getShopkeeperProfile() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/profile');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 404) {
      return null;
    }
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return ShopkeeperProfileModel.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  Future<ShopkeeperProfileModel> upsertShopkeeperProfile({
    required String shopName,
    String? address,
    String? pincode,
    String? city,
    String? category,
    String? description,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/profile');
    final resp = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'shopName': shopName,
        if (address != null) 'address': address,
        if (pincode != null) 'pincode': pincode,
        if (city != null) 'city': city,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return ShopkeeperProfileModel.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  // Shopkeeper offers
  Future<List<OfferModel>> getShopkeeperOffers() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final list = (data['offers'] as List<dynamic>? ?? []);
    return list
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Customer offers (by pincode or user's pincode)
  Future<List<OfferModel>> getCustomerOffers() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final user = AuthStore.currentUser;
    final pincode = user?.pincode;
    final query =
        (pincode != null && pincode.isNotEmpty) ? '?pincode=$pincode' : '';
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/offers$query');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final list = (data['offers'] as List<dynamic>? ?? []);
    return list
        .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OfferModel> createOffer({
    required String title,
    String? description,
    String? discountType,
    dynamic discountValue,
    DateTime? validFrom,
    DateTime? validTo,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers');
    final resp = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        if (description != null) 'description': description,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (validFrom != null) 'validFrom': validFrom.toIso8601String(),
        if (validTo != null) 'validTo': validTo.toIso8601String(),
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return OfferModel.fromJson(data['offer'] as Map<String, dynamic>);
  }

  Future<OfferModel> updateOffer({
    required String id,
    String? title,
    String? description,
    String? discountType,
    dynamic discountValue,
    DateTime? validFrom,
    DateTime? validTo,
    String? status,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers/$id');
    final resp = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (validFrom != null) 'validFrom': validFrom.toIso8601String(),
        if (validTo != null) 'validTo': validTo.toIso8601String(),
        if (status != null) 'status': status,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return OfferModel.fromJson(data['offer'] as Map<String, dynamic>);
  }

  Future<void> deleteOffer(String id) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers/$id');
    final resp = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(resp);
  }

  // Pincode lookup
  Future<Map<String, dynamic>> lookupPincode(String pincode) async {
    final uri = Uri.parse('${ApiConfig.metaUrl}/pincode/$pincode');
    final resp = await _client.get(uri);
    final data = _handleResponse(resp) as Map<String, dynamic>;

    // Parse areas list
    final areasList = (data['areas'] as List<dynamic>?)?.map((area) {
          return {
            'name': area['name']?.toString() ?? '',
            'district': area['district']?.toString() ?? '',
            'block': area['block']?.toString() ?? '',
          };
        }).toList() ??
        [];

    return {
      'pincode': data['pincode']?.toString() ?? pincode,
      'state': data['state']?.toString() ?? '',
      'district': data['district']?.toString() ?? '',
      'areas': areasList,
    };
  }

  // Admin shopkeepers
  Future<Map<String, dynamic>> getAdminStats() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.adminUrl}/stats');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['stats'] as Map<String, dynamic>;
  }

  Future<List<UserModel>> getUsers(
      {String? role, int? limit, int? skip}) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final queryParams = <String, String>{};
    if (role != null) queryParams['role'] = role;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (skip != null) queryParams['skip'] = skip.toString();
    final query = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    final uri = Uri.parse('${ApiConfig.adminUrl}/users$query');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final list = (data['users'] as List<dynamic>? ?? []);
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getShopkeepers({String? status}) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final query = status != null ? '?status=$status' : '';
    final uri = Uri.parse('${ApiConfig.adminUrl}/shopkeepers$query');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final list = (data['shopkeepers'] as List<dynamic>? ?? []);
    return list
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveShopkeeper(String id) async {
    await _patchShopkeeperStatus(id, 'approve');
  }

  Future<void> rejectShopkeeper(String id) async {
    await _patchShopkeeperStatus(id, 'reject');
  }

  Future<void> _patchShopkeeperStatus(String id, String action) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.adminUrl}/shopkeepers/$id/$action');
    final resp = await _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(resp);
  }

  Object _handleResponse(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      try {
        final data = jsonDecode(resp.body);
        final message = data['message']?.toString() ?? 'Request failed';
        throw Exception(message);
      } catch (_) {
        throw Exception('Request failed with status ${resp.statusCode}');
      }
    }
    if (resp.body.isEmpty) return {};
    final data = jsonDecode(resp.body);
    return data;
  }
}
