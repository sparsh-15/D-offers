import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/campaign_model.dart';
import 'api_config.dart';
import 'auth_store.dart';

class CampaignAccessException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic> details;

  CampaignAccessException({
    required this.code,
    required this.message,
    this.details = const {},
  });

  @override
  String toString() => message;
}

class CampaignService {
  CampaignService._internal();

  static final CampaignService _instance = CampaignService._internal();

  static CampaignService get instance => _instance;

  final http.Client _client = http.Client();

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (AuthStore.token != null) 'Authorization': 'Bearer ${AuthStore.token}',
    };
  }

  Uri _shopkeeperUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${ApiConfig.shopkeeperUrl}$path').replace(
      queryParameters: queryParameters,
    );
  }

  Uri _customerUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.parse('${ApiConfig.baseUrl}/customer$path').replace(
      queryParameters: queryParameters,
    );
  }

  dynamic _decode(http.Response response) {
    return jsonDecode(response.body);
  }

  void _ensureSuccess(http.Response response, dynamic data) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic> && data['success'] == true) {
        return;
      }
    }
    if (response.statusCode == 403 && data is Map<String, dynamic>) {
      throw CampaignAccessException(
        code: data['code']?.toString() ?? 'ACCESS_DENIED',
        message: data['message']?.toString() ?? 'Access denied',
        details: data['details'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['details'] as Map<String, dynamic>)
            : const {},
      );
    }
    final message = data is Map<String, dynamic>
        ? data['message']?.toString() ?? 'Request failed'
        : 'Request failed';
    throw Exception(message);
  }

  Future<List<CampaignModel>> getCampaigns({
    String? status,
    int offset = 0,
    int limit = 20,
  }) async {
    final queryParameters = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
    };
    final response = await _client.get(
      _shopkeeperUri('/campaigns', queryParameters),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    final campaigns = List<Map<String, dynamic>>.from(data['campaigns'] ?? const []);
    return campaigns.map(CampaignModel.fromJson).toList();
  }

  Future<CampaignModel> getCampaign(String campaignId) async {
    final response = await _client.get(
      _shopkeeperUri('/campaigns/$campaignId'),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return CampaignModel.fromJson(
      Map<String, dynamic>.from(data['campaign'] as Map? ?? const {}),
    );
  }

  Future<AudienceEstimate> estimateAudience(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _shopkeeperUri('/campaigns/estimate-audience'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return AudienceEstimate.fromJson(
      Map<String, dynamic>.from(data['data'] as Map? ?? const {}),
    );
  }

  Future<CampaignModel> createCampaign(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _shopkeeperUri('/campaigns'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return CampaignModel.fromJson(
      Map<String, dynamic>.from(data['campaign'] as Map? ?? const {}),
    );
  }

  Future<CampaignModel> updateCampaign(
    String campaignId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _client.put(
      _shopkeeperUri('/campaigns/$campaignId'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return CampaignModel.fromJson(
      Map<String, dynamic>.from(data['campaign'] as Map? ?? const {}),
    );
  }

  Future<CampaignModel> payCampaign(
    String campaignId, {
    required String paymentMethod,
    String? transactionId,
  }) async {
    final response = await _client.post(
      _shopkeeperUri('/campaigns/$campaignId/pay'),
      headers: _headers(),
      body: jsonEncode({
        'paymentMethod': paymentMethod,
        if (transactionId != null && transactionId.isNotEmpty)
          'transactionId': transactionId,
      }),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return CampaignModel.fromJson(
      Map<String, dynamic>.from(data['campaign'] as Map? ?? const {}),
    );
  }

  Future<void> cancelCampaign(String campaignId) async {
    final response = await _client.post(
      _shopkeeperUri('/campaigns/$campaignId/cancel'),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
  }

  Future<void> deleteCampaign(String campaignId) async {
    final response = await _client.delete(
      _shopkeeperUri('/campaigns/$campaignId'),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
  }

  Future<int> getUnreadInboxCount() async {
    final response = await _client.get(
      _customerUri('/inbox/unread-count'),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    return int.tryParse(data['count']?.toString() ?? '0') ?? 0;
  }

  Future<List<CampaignTemplateModel>> getCampaignTemplates({
    String? category,
  }) async {
    final response = await _client.get(
      _shopkeeperUri(
        '/campaigns/templates',
        category != null && category.isNotEmpty ? {'category': category} : null,
      ),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    final templates = List<Map<String, dynamic>>.from(
      data['templates'] ?? const [],
    );
    return templates.map(CampaignTemplateModel.fromJson).toList();
  }

  Future<List<InboxMessageModel>> getInboxMessages({
    int offset = 0,
    int limit = 30,
  }) async {
    final response = await _client.get(
      _customerUri('/inbox', {
        'offset': '$offset',
        'limit': '$limit',
      }),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
    final messages = List<Map<String, dynamic>>.from(
      data['messages'] ?? const [],
    );
    return messages.map(InboxMessageModel.fromJson).toList();
  }

  Future<void> markInboxMessageRead(String inboxMessageId) async {
    final response = await _client.patch(
      _customerUri('/inbox/$inboxMessageId/read'),
      headers: _headers(),
    );
    final data = _decode(response);
    _ensureSuccess(response, data);
  }
}