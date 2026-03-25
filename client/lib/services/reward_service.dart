import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/role_enum.dart';
import 'api_config.dart';
import 'auth_store.dart';

class RewardService {
  RewardService._();

  static final RewardService instance = RewardService._();

  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.baseUrl}/rewards$path').replace(
        queryParameters: query == null || query.isEmpty ? null : query);
  }

  Map<String, String> _authHeaders({String? idempotencyKey}) {
    final token = AuthStore.token;
    if (token == null) {
      throw Exception('Not authenticated');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'Idempotency-Key': idempotencyKey,
    };
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timeout');
    }
  }

  dynamic _handle(http.Response response) {
    Map<String, dynamic> data = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message']?.toString() ??
        'Request failed (${response.statusCode})';
    throw Exception(message);
  }

  String _buildStableIdempotencyKey(String action, String sourceRef) {
    final userId = AuthStore.currentUser?.id ?? 'unknown';
    return '$action:$userId:$sourceRef';
  }

  Future<Map<String, dynamic>> getMyWallet() async {
    final response = await _send(() => _client.get(
          _uri('/wallet/me'),
          headers: _authHeaders(),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    return (data['wallet'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> getMyLedger(
      {int limit = 25, int skip = 0}) async {
    final response = await _send(() => _client.get(
          _uri('/wallet/me/ledger', {
            'limit': '$limit',
            'skip': '$skip',
          }),
          headers: _authHeaders(),
        ));
    return _handle(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyExpirySummary() async {
    final response = await _send(() => _client.get(
          _uri('/wallet/me/expiry-summary'),
          headers: _authHeaders(),
        ));
    return _handle(response) as Map<String, dynamic>;
  }

  Future<void> awardLikeReward(String offerId) async {
    final sourceRef = offerId.trim();
    if (sourceRef.isEmpty) return;

    final response = await _send(() => _client.post(
          _uri('/customer/like'),
          headers: _authHeaders(
            idempotencyKey: _buildStableIdempotencyKey('like_offer', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'offerId': sourceRef,
          }),
        ));

    _handle(response);
  }

  Future<void> awardPurchaseReward(String purchaseRef) async {
    final sourceRef = purchaseRef.trim();
    if (sourceRef.isEmpty) return;

    final response = await _send(() => _client.post(
          _uri('/customer/purchase-success'),
          headers: _authHeaders(
            idempotencyKey:
                _buildStableIdempotencyKey('purchase_success', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'purchaseId': sourceRef,
            'validationStatus': 'validated',
          }),
        ));

    _handle(response);
  }

  Future<void> awardShopSaleReward(String saleId) async {
    final sourceRef = saleId.trim();
    if (sourceRef.isEmpty) return;

    final response = await _send(() => _client.post(
          _uri('/shopkeeper/sale-closed'),
          headers: _authHeaders(
            idempotencyKey:
                _buildStableIdempotencyKey('sale_closed', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'saleId': sourceRef,
          }),
        ));

    _handle(response);
  }

  Future<void> awardInstallReward(
      {required String installId, required String deviceFingerprint}) async {
    final sourceRef = installId.trim();
    if (sourceRef.isEmpty) return;

    final response = await _send(() => _client.post(
          _uri('/shopkeeper/install-verified'),
          headers: _authHeaders(
            idempotencyKey:
                _buildStableIdempotencyKey('install_verified', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'installId': sourceRef,
            'deviceFingerprint': deviceFingerprint,
          }),
        ));

    _handle(response);
  }

  Future<Map<String, dynamic>> getShopkeeperMilestones() async {
    final response = await _send(() => _client.get(
          _uri('/shopkeeper/milestones/me'),
          headers: _authHeaders(),
        ));
    return _handle(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> redeemMilestone(String milestoneId) async {
    final response = await _send(() => _client.post(
          _uri('/shopkeeper/milestones/$milestoneId/redeem'),
          headers: _authHeaders(),
        ));
    return _handle(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminRewardMetrics() async {
    final response = await _send(() => _client.get(
          _uri('/admin/metrics'),
          headers: _authHeaders(),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    return (data['metrics'] as Map<String, dynamic>?) ?? const {};
  }

  Future<List<Map<String, dynamic>>> listRewardConfigs() async {
    final response = await _send(() => _client.get(
          _uri('/admin/config'),
          headers: _authHeaders(),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    return (data['configs'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<Map<String, dynamic>> updateRewardConfig({
    required String key,
    required Map<String, dynamic> value,
  }) async {
    final response = await _send(() => _client.put(
          _uri('/admin/config/$key'),
          headers: _authHeaders(),
          body: jsonEncode({'value': value}),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    return (data['config'] as Map<String, dynamic>?) ?? const {};
  }

  bool get isCustomer {
    return AuthStore.currentUser?.role == UserRole.customer;
  }

  bool get isShopkeeper {
    return AuthStore.currentUser?.role == UserRole.shopkeeper;
  }
}
