import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/role_enum.dart';
import 'api_config.dart';
import 'auth_store.dart';

class RewardService {
  RewardService._();

  static final RewardService instance = RewardService._();

  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);
  final ValueNotifier<int?> walletBalanceNotifier = ValueNotifier<int?>(null);
  final Random _random = Random();

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

    var message = data['message']?.toString() ??
        'Request failed (${response.statusCode})';

    if (response.statusCode == 403 &&
        data['code']?.toString() == 'INSUFFICIENT_PERMISSIONS') {
      final userRole = data['userRole']?.toString();
      final requiredRoles =
          (data['requiredRoles'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();

      if (userRole != null && requiredRoles.isNotEmpty) {
        message =
            'Insufficient permissions (userRole=$userRole, required=${requiredRoles.join('/')})';
      }
    }

    throw Exception(message);
  }

  String _buildRequestIdempotencyKey(String action, String sourceRef) {
    final userId = AuthStore.currentUser?.id ?? 'unknown';
    final nonce = _random.nextInt(1 << 32).toRadixString(16);
    return '$action:$userId:$sourceRef:${DateTime.now().microsecondsSinceEpoch}:$nonce';
  }

  String _buildStableIdempotencyKey(String action, String sourceRef) {
    final userId = AuthStore.currentUser?.id ?? 'unknown';
    return '$action:$userId:$sourceRef';
  }

  int? _parseBalance(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final trimmed = raw.trim();
      final intValue = int.tryParse(trimmed);
      if (intValue != null) return intValue;
      final doubleValue = double.tryParse(trimmed);
      if (doubleValue != null) return doubleValue.toInt();
    }
    return null;
  }

  void _publishBalance(int? balance) {
    if (balance == null) return;
    if (walletBalanceNotifier.value != balance) {
      walletBalanceNotifier.value = balance;
    }
  }

  int? _extractLedgerAmount(Map<String, dynamic>? payload) {
    final ledger = payload?['ledgerEntry'];
    if (ledger is Map<String, dynamic>) {
      return _parseBalance(ledger['amount']);
    }
    return null;
  }

  int? get latestWalletBalance => walletBalanceNotifier.value;

  Future<int?> refreshMyWalletBalance() async {
    try {
      final wallet = await getMyWallet();
      final balance = _parseBalance(wallet['balance']);
      _publishBalance(balance);
      return balance;
    } catch (_) {
      return latestWalletBalance;
    }
  }

  Future<Map<String, dynamic>> getMyWallet() async {
    final response = await _send(() => _client.get(
          _uri('/wallet/me'),
          headers: _authHeaders(),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    final wallet = (data['wallet'] as Map<String, dynamic>?) ?? const {};
    _publishBalance(_parseBalance(wallet['balance']));
    return wallet;
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

  Future<Map<String, dynamic>> awardLikeReward(String offerId) async {
    final sourceRef = offerId.trim();
    if (sourceRef.isEmpty) return const {'success': false, 'duplicate': false};

    final response = await _send(() => _client.post(
          _uri('/customer/like'),
          headers: _authHeaders(
            idempotencyKey:
                _buildRequestIdempotencyKey('like_offer', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'offerId': sourceRef,
          }),
        ));

    final data = _handle(response) as Map<String, dynamic>;
    final walletBalance = _parseBalance(data['walletBalance']);
    if (walletBalance != null) {
      _publishBalance(walletBalance);
    } else {
      final amount = _extractLedgerAmount(data);
      if (amount != null) {
        _publishBalance((latestWalletBalance ?? 0) + amount);
      } else {
        await refreshMyWalletBalance();
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> reverseLikeReward(String offerId) async {
    final sourceRef = offerId.trim();
    if (sourceRef.isEmpty)
      return const {'reversed': false, 'reason': 'SOURCE_REF_REQUIRED'};

    final response = await _send(() => _client.post(
          _uri('/customer/unlike'),
          headers: _authHeaders(
            idempotencyKey:
                _buildRequestIdempotencyKey('unlike_offer', sourceRef),
          ),
          body: jsonEncode({
            'sourceRef': sourceRef,
            'offerId': sourceRef,
          }),
        ));

    final data = _handle(response) as Map<String, dynamic>;
    final walletBalance = _parseBalance(data['walletBalance']);
    if (walletBalance != null) {
      _publishBalance(walletBalance);
    } else if (data['reversed'] == true) {
      final amount = _extractLedgerAmount(data);
      if (amount != null) {
        _publishBalance((latestWalletBalance ?? 0) - amount);
      } else {
        await refreshMyWalletBalance();
      }
    }
    return data;
  }

  String? unlikeReversalReasonMessage(String? reason) {
    switch (reason) {
      case 'INSUFFICIENT_BALANCE':
        return 'Unlike saved, coin reversal blocked due to low balance.';
      case 'REVERSAL_WINDOW_EXPIRED':
        return 'Unlike saved, reversal window has expired.';
      case 'REVERSAL_DISABLED':
        return 'Unlike saved, coin reversal is currently disabled.';
      case 'ALREADY_REVERSED':
        return null;
      case 'NO_LIKE_REWARD_FOUND':
        return null;
      case 'WALLET_NOT_FOUND':
        return 'Unlike saved, but wallet was not found for reversal.';
      default:
        return 'Unlike saved, but coin reversal could not be completed.';
    }
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

    final data = _handle(response) as Map<String, dynamic>;
    _publishBalance(_parseBalance(data['walletBalance']));
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

    final data = _handle(response) as Map<String, dynamic>;
    _publishBalance(_parseBalance(data['walletBalance']));
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

    final data = _handle(response) as Map<String, dynamic>;
    _publishBalance(_parseBalance(data['walletBalance']));
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
    int? version,
  }) async {
    final response = await _send(() => _client.put(
          _uri('/admin/config/$key'),
          headers: _authHeaders(),
          body: jsonEncode({
            'value': value,
            if (version != null) 'version': version,
          }),
        ));
    final data = _handle(response) as Map<String, dynamic>;
    return (data['config'] as Map<String, dynamic>?) ?? const {};
  }

  bool get isCustomer {
    return AuthStore.currentUser?.hasRole(UserRole.customer) ?? false;
  }

  bool get isShopkeeper {
    return AuthStore.currentUser?.hasRole(UserRole.shopkeeper) ?? false;
  }
}
