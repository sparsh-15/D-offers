import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/api_config.dart';
import 'auth_store.dart';

class ShopkeeperAiService {
  ShopkeeperAiService._();

  static final ShopkeeperAiService instance = ShopkeeperAiService._();

  static const Duration _timeout = Duration(seconds: 40);

  Future<String> generateBannerImageUrl({
    required String title,
    String? description,
    String? category,
    String? discountType,
    num? discountValue,
    String? shopName,
  }) async {
    final token = AuthStore.token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('${ApiConfig.shopkeeperUrl}/ai/banner');
    final body = <String, dynamic>{
      'title': title,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (discountType != null && discountType.isNotEmpty)
        'discountType': discountType,
      if (discountValue != null) 'discountValue': discountValue,
      if (shopName != null && shopName.trim().isNotEmpty)
        'shopName': shopName.trim(),
    };

    final resp = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (resp.statusCode == 403) {
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final code = data['code']?.toString() ?? '';
        final message = data['message']?.toString() ??
            'You have reached your AI banner limit. Buy AI Credit Pack.';
        if (code == 'AI_NO_CREDITS' || code == 'AI_LIMIT_REACHED') {
          throw Exception(message);
        }
      } catch (_) {
        // fall through to generic handler
      }
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      try {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final message =
            data['message']?.toString() ?? 'Failed to generate AI banner';
        throw Exception(message);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to generate AI banner (status ${resp.statusCode})');
      }
    }

    if (resp.body.isEmpty) {
      throw Exception('Empty response from AI banner service');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final payload = data['data'] as Map<String, dynamic>?;
    final imageUrl = payload?['imageUrl']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('AI banner response did not include an image URL');
    }
    return imageUrl;
  }
}

