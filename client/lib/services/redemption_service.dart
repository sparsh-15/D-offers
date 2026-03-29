import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/redemption_model.dart';
import 'api_config.dart';
import 'auth_store.dart';

class RedemptionService {
  RedemptionService._internal();

  static final RedemptionService _instance = RedemptionService._internal();

  static RedemptionService get instance => _instance;

  final http.Client _client = http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${ApiConfig.businessUrl}/redemptions$path').replace(
      queryParameters: query,
    );
  }

  Map<String, String> _headers({String? idempotencyKey}) {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.token != null) 'Authorization': 'Bearer ${AuthStore.token}',
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'x-idempotency-key': idempotencyKey,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  Map<String, dynamic> _ensureSuccess(http.Response response) {
    final data = _decode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'Request failed');
  }

  String _idempotencyKey(String couponCode, String offerId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'redeem-$now-${couponCode.trim().toUpperCase()}-$offerId';
  }

  Future<RedemptionResponse> verify({
    required String couponCode,
    required String offerId,
  }) async {
    final response = await _client.post(
      _uri('/verify'),
      headers: _headers(),
      body: jsonEncode({
        'couponCode': couponCode.trim(),
        'offerId': offerId,
      }),
    );

    final data = _ensureSuccess(response);
    final payload = Map<String, dynamic>.from(data['data'] as Map? ?? const {});

    return RedemptionResponse.fromJson({
      ...payload,
      'message': data['message']?.toString() ?? '',
    });
  }

  Future<RedemptionResponse> manualVerify({
    required String couponCode,
    required String offerId,
  }) async {
    final response = await _client.post(
      _uri('/manual-verify'),
      headers: _headers(),
      body: jsonEncode({
        'couponCode': couponCode.trim(),
        'offerId': offerId,
      }),
    );

    final data = _ensureSuccess(response);
    final payload = Map<String, dynamic>.from(data['data'] as Map? ?? const {});

    return RedemptionResponse.fromJson({
      ...payload,
      'message': data['message']?.toString() ?? '',
    });
  }

  Future<RedemptionResponse> redeem({
    required String couponCode,
    required String offerId,
    String verificationMethod = 'qr',
  }) async {
    final idempotencyKey = _idempotencyKey(couponCode, offerId);

    final response = await _client.post(
      _uri('/redeem'),
      headers: _headers(idempotencyKey: idempotencyKey),
      body: jsonEncode({
        'couponCode': couponCode.trim(),
        'offerId': offerId,
        'verificationMethod': verificationMethod,
      }),
    );

    final data = _ensureSuccess(response);
    final payload = Map<String, dynamic>.from(data['data'] as Map? ?? const {});

    return RedemptionResponse.fromJson({
      ...payload,
      'message': data['message']?.toString() ?? '',
    });
  }

  Future<RedemptionHistoryPage> history({
    int offset = 0,
    int limit = 20,
    String? offerId,
  }) async {
    final response = await _client.get(
      _uri('/history', {
        'offset': '$offset',
        'limit': '$limit',
        if (offerId != null && offerId.isNotEmpty) 'offerId': offerId,
      }),
      headers: _headers(),
    );

    final data = _ensureSuccess(response);
    return RedemptionHistoryPage.fromJson(data);
  }
}
