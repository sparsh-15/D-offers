import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import '../models/user_model.dart';
import '../models/role_enum.dart';
import '../models/offer_model.dart';
import '../models/shopkeeper_profile_model.dart';
import 'auth_store.dart';

class AuthService {
  AuthService._() {
    // Configure HTTP client to handle SSL certificates properly
    HttpOverrides.global = _MyHttpOverrides();
  }

  static final AuthService instance = AuthService._();

  final http.Client _client = http.Client();

  // Timeout duration for API calls
  static const Duration _timeout = Duration(seconds: 30);

  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception(
          'Network error: Please check your internet connection. ${e.message}');
    } on TimeoutException catch (_) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<void> signup({
    required UserRole role,
    required String phone,
    required String name,
    required String pincode,
    required bool acceptedTerms,
    String? city,
    String? address,
    String? couponCode,
    String? gender,
    String? dob, // ISO or simple date string
    String? occupation,
    String? aboutMe,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/signup');
    final body = <String, dynamic>{
      'role': roleToString(role),
      'phone': phone,
      'name': name,
      'pincode': pincode,
      'city': city ?? '',
      'address': address ?? '',
      'acceptedTerms': acceptedTerms,
    };
    if (couponCode != null && couponCode.trim().isNotEmpty) {
      body['couponCode'] = couponCode.trim();
    }
    if (gender != null && gender.trim().isNotEmpty) {
      body['gender'] = gender.trim();
    }
    if (dob != null && dob.trim().isNotEmpty) {
      body['dob'] = dob.trim();
    }
    if (occupation != null && occupation.trim().isNotEmpty) {
      body['occupation'] = occupation.trim();
    }
    if (aboutMe != null && aboutMe.trim().isNotEmpty) {
      body['aboutMe'] = aboutMe.trim();
    }
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _handleResponse(resp);
  }

  Future<void> sendOtp({
    UserRole? role,
    required String phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/send-otp');
    print(
        '[AUTH] Sending OTP - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');

    try {
      final resp = await _makeRequest(() => _client.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (role != null) 'role': roleToString(role),
              'phone': phone,
            }),
          ));

      if (resp.statusCode == 429) {
        print(
            '[AUTH] Rate limit exceeded (429) - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');
        throw Exception(
            'Too many login attempts. Please wait 15 minutes before trying again.');
      }

      _handleResponse(resp);
      print(
          '[AUTH] OTP sent successfully - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');
    } catch (e) {
      print(
          '[AUTH] sendOtp error - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***, Error: $e');
      rethrow;
    }
  }

  Future<void> verifyOtp({
    UserRole? role,
    required String phone,
    required String otp,
  }) async {
    final uri = Uri.parse('${ApiConfig.authUrl}/verify-otp');
    print(
        '[AUTH] Verifying OTP - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');

    try {
      final resp = await _makeRequest(() => _client.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              if (role != null) 'role': roleToString(role),
              'phone': phone,
              'otp': otp,
            }),
          ));

      if (resp.statusCode == 429) {
        print(
            '[AUTH] Rate limit exceeded (429) during OTP verification - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');
        throw Exception(
            'Too many verification attempts. Please wait 15 minutes before trying again.');
      }

      final data = _handleResponse(resp) as Map<String, dynamic>;
      final token = data['token']?.toString();
      if (token == null) {
        print('[AUTH] verifyOtp error - Token not returned from server');
        throw Exception('Token not returned from server');
      }
      AuthStore.token = token;
      print(
          '[AUTH] OTP verified successfully - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***');
      // Fetch full user profile via /me so we get approvalStatus etc.
      AuthStore.currentUser = await fetchCurrentUser();
      print(
          '[AUTH] User profile fetched successfully - Role: ${role != null ? roleToString(role) : 'auto'}');
    } catch (e) {
      print(
          '[AUTH] verifyOtp error - Role: ${role != null ? roleToString(role) : 'auto'}, Phone: ${phone.substring(0, 3)}***, Error: $e');
      rethrow;
    }
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

  Future<UserModel> updateCurrentUser({
    String? name,
    String? address,
    String? pincode,
    String? city,
    String? state,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.authUrl}/me');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (address != null) body['address'] = address;
    if (pincode != null) body['pincode'] = pincode;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    final resp = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    AuthStore.currentUser = user;
    return user;
  }

  /// Customer becomes SSA. Requires current user to be customer. Returns updated user.
  Future<UserModel> becomeSSA({
    String? email,
    required String pincode,
    String? city,
    String? state,
    String? region,
    int? maxCouponDiscountPercent,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/become-ssa');
    final body = <String, dynamic>{
      'pincode': pincode.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (state != null && state.trim().isNotEmpty) 'state': state.trim(),
      if (region != null && region.trim().isNotEmpty) 'region': region.trim(),
      if (maxCouponDiscountPercent != null)
        'maxCouponDiscountPercent': maxCouponDiscountPercent,
    };
    final resp = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    AuthStore.currentUser = user;
    return user;
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

  // Public shop profile for customers (by shopkeeperId)
  Future<ShopkeeperProfileModel?> getPublicShopProfile(
    String shopkeeperId,
  ) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/customer/shops/$shopkeeperId/profile',
    );
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
    List<String>? shopImages,
    String? logoUrl,
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
        if (shopImages != null) 'shopImages': shopImages,
        if (logoUrl != null) 'logoUrl': logoUrl,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return ShopkeeperProfileModel.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  Future<ShopkeeperProfileModel> updateShopImages(List<String> images) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/profile/images');
    final resp = await _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'images': images}),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return ShopkeeperProfileModel.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  Future<ShopkeeperProfileModel> updateLogoUrl(String? logoUrl) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/profile/logo');
    final resp = await _client.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'logoUrl': logoUrl}),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return ShopkeeperProfileModel.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  // Onboarding - shopkeeper
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/onboarding/status');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['onboarding'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeOnboardingProfile() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/onboarding/complete-profile');
    final resp = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['onboarding'] as Map<String, dynamic>;
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

  // Customer offers with optional filters
  Future<List<OfferModel>> getCustomerOffers({
    String? state,
    String? city,
    String? pincode,
    String? q,
    String? category,
    String? sort,
    String? segment,
    int? limit,
    int? offset,
  }) async {
    final page = await getCustomerOffersPage(
      state: state,
      city: city,
      pincode: pincode,
      q: q,
      category: category,
      sort: sort,
      segment: segment,
      limit: limit,
      offset: offset,
    );
    return page['offers'] as List<OfferModel>;
  }

  Future<Map<String, dynamic>> getCustomerOffersPage({
    String? state,
    String? city,
    String? pincode,
    String? q,
    String? category,
    String? sort,
    String? segment,
    int? limit,
    int? offset,
    String? cursor,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final params = <String, String>{};
    if (pincode != null && pincode.isNotEmpty) {
      params['pincode'] = pincode;
    } else {
      if (city != null && city.isNotEmpty) {
        params['city'] = city;
      }
      if (state != null && state.isNotEmpty) {
        params['state'] = state;
      }
    }
    if (q != null && q.trim().isNotEmpty) {
      params['q'] = q.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (sort != null && sort.trim().isNotEmpty) {
      params['sort'] = sort.trim();
    }
    if (segment != null && segment.trim().isNotEmpty) {
      params['segment'] = segment.trim();
    }
    if (limit != null && limit > 0) {
      params['limit'] = limit.toString();
    }
    if (offset != null && offset >= 0) {
      params['offset'] = offset.toString();
    } else if (cursor != null && cursor.trim().isNotEmpty) {
      // Backward compatibility: older callers may still pass cursor.
      params['cursor'] = cursor.trim();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/offers')
        .replace(queryParameters: params.isEmpty ? null : params);

    try {
      final resp = await _makeRequest(() => _client.get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
            },
          ));

      if (resp.statusCode == 429) {
        throw Exception(
            'Too many requests. Please wait a moment and try again.');
      }

      final data = _handleResponse(resp) as Map<String, dynamic>;

      final list = (data['offers'] as List<dynamic>? ?? []);
      final offers = list
          .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pageInfo = (data['pageInfo'] as Map<String, dynamic>?) ?? const {};
      return {
        'offers': offers,
        'pageInfo': pageInfo,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> toggleOfferLike(String offerId) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/offers/$offerId/like');
    final resp = await _makeRequest(() => _client.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ));
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return {
      'isLiked': data['isLiked'] as bool? ?? false,
      'likesCount': data['likesCount'] as int? ?? 0,
    };
  }

  Future<void> requestOfferCallback(
    String offerId, {
    String? message,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/callbacks');
    final body = <String, dynamic>{
      'offerId': offerId,
      if (message != null && message.trim().isNotEmpty)
        'message': message.trim(),
    };
    final resp = await _makeRequest(
      () => _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ),
    );
    _handleResponse(resp);
  }

  Future<List<OfferModel>> getLikedOffers() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.baseUrl}/customer/offers/liked');
    final resp = await _makeRequest(() => _client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ));
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
    List<String>? photos,
    String? termsAndConditions,
    String? category,
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
        if (photos != null) 'photos': photos,
        if (termsAndConditions != null)
          'termsAndConditions': termsAndConditions,
        if (category != null) 'category': category,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return OfferModel.fromJson(data['offer'] as Map<String, dynamic>);
  }

  Future<OfferModel> updateOffer({
    required String offerId,
    String? title,
    String? description,
    String? discountType,
    dynamic discountValue,
    DateTime? validFrom,
    DateTime? validTo,
    String? status,
    List<String>? photos,
    String? termsAndConditions,
    String? category,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers/$offerId');
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
        if (photos != null) 'photos': photos,
        if (termsAndConditions != null)
          'termsAndConditions': termsAndConditions,
        if (category != null) 'category': category,
      }),
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return OfferModel.fromJson(data['offer'] as Map<String, dynamic>);
  }

  Future<void> deleteOffer(String offerId) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/offers/$offerId');
    final resp = await _client.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    _handleResponse(resp);
  }

  Future<Map<String, dynamic>> getShopkeeperDashboard() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/dashboard');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['dashboard'] as Map<String, dynamic>;
  }

  // Pincode lookup
  Future<Map<String, dynamic>> lookupPincode(String pincode) async {
    final uri = Uri.parse('${ApiConfig.metaUrl}/pincode/$pincode');
    final resp = await _client.get(uri);
    final response = _handleResponse(resp) as Map<String, dynamic>;
    final data = (response['data'] as Map<String, dynamic>?) ?? response;

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

  Future<List<UserModel>> getUsers({
    String? role,
    String? state,
    String? city,
    String? category,
    int? limit,
    int? skip,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final queryParams = <String, String>{};
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
    if (limit != null) queryParams['limit'] = limit.toString();
    if (skip != null) queryParams['skip'] = skip.toString();
    final query = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
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

  Future<Map<String, dynamic>> getUsersStats({
    String? role,
    String? state,
    String? city,
    String? category,
  }) async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final queryParams = <String, String>{};
    if (role != null && role.isNotEmpty) queryParams['role'] = role;
    if (state != null && state.isNotEmpty) queryParams['state'] = state;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (category != null && category.isNotEmpty)
      queryParams['category'] = category;
    final query = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final uri = Uri.parse('${ApiConfig.adminUrl}/users/stats$query');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['stats'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLocationOptions() async {
    final token = AuthStore.token;
    if (token == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${ApiConfig.adminUrl}/meta/locations');
    final resp = await _client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    final data = _handleResponse(resp) as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
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
      print(
          '[AUTH] HTTP Error - Status: ${resp.statusCode}, Body: ${resp.body}');
      try {
        final data = jsonDecode(resp.body);
        final message = data['message']?.toString() ?? 'Request failed';

        // Handle 429 specifically
        if (resp.statusCode == 429) {
          throw Exception(
              'Too many attempts. Please wait 15 minutes before trying again.');
        }

        throw Exception(message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Request failed with status ${resp.statusCode}');
      }
    }
    if (resp.body.isEmpty) {
      print('[AUTH] Empty response body');
      return {};
    }
    try {
      final data = jsonDecode(resp.body);
      print('[AUTH] Successfully decoded JSON response');
      return data;
    } catch (e) {
      print('[AUTH] JSON decode error - Body: ${resp.body}');
      print('[AUTH] JSON decode error details: $e');
      throw Exception('Invalid response from server: $e');
    }
  }
}

// Custom HttpOverrides to handle SSL certificates for production
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // In production, you should validate the certificate properly
        // For now, accept all certificates to avoid SSL issues
        return true;
      };
  }
}
