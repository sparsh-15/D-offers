import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_store.dart';

/// Thrown when the backend returns 403 with code AI_LIMIT_REACHED (e.g. no AI credits left).
class AiLimitReachedException implements Exception {
  @override
  String toString() => "You have reached your AI banner limit. Buy AI Credit Pack.";
}

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static SubscriptionService get instance => _instance;

  final _client = http.Client();

  String? _getAuthToken() {
    return AuthStore.token;
  }

  Map<String, String> _getHeaders() {
    final token = _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============ Categories ============

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/meta/categories');
      print('[SUBSCRIPTION] Fetching categories');

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categories = List<Map<String, dynamic>>.from(data['data']);
          print('[SUBSCRIPTION] Fetched ${categories.length} categories');
          return categories;
        }
      }

      throw Exception('Failed to fetch categories');
    } catch (e) {
      print('[SUBSCRIPTION] getCategories error: $e');
      rethrow;
    }
  }

  // ============ Plans Management ============

  Future<List<Map<String, dynamic>>> getAllPlans({
    bool? isActive,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (category != null) queryParams['category'] = category;

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/plans',
      ).replace(queryParameters: queryParams);

      print('[SUBSCRIPTION] Fetching plans: $uri');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final plans = List<Map<String, dynamic>>.from(data['data']);
          print('[SUBSCRIPTION] Fetched ${plans.length} plans');
          return plans;
        }
      }

      throw Exception('Failed to fetch plans');
    } catch (e) {
      print('[SUBSCRIPTION] getAllPlans error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPlan({
    required String name,
    required String displayName,
    required String category,
    required double monthlyPrice,
    String? description,
    List<String>? features,
    int maxOffers = -1,
    int maxPhotosPerOffer = 5,
    bool analyticsEnabled = false,
    bool prioritySupport = false,
    int sortOrder = 0,
    int monthlyAiLimit = 0,
    String rankingTier = 'normal',
    bool homepageRotation = false,
    bool aiOptimizationSuggestions = false,
    String aiCreditTier = 'silver',
    String? tier,
  }) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.baseUrl}/subscription-governance/plans');
      print('[SUBSCRIPTION] Creating plan: $name');

      final body = {
        'name': name,
        'displayName': displayName,
        'category': category,
        'monthlyPrice': monthlyPrice,
        if (description != null) 'description': description,
        if (features != null) 'features': features,
        'maxOffers': maxOffers,
        'maxPhotosPerOffer': maxPhotosPerOffer,
        'analyticsEnabled': analyticsEnabled,
        'prioritySupport': prioritySupport,
        'sortOrder': sortOrder,
        'monthlyAiLimit': monthlyAiLimit,
        'rankingTier': rankingTier,
        'homepageRotation': homepageRotation,
        'aiOptimizationSuggestions': aiOptimizationSuggestions,
        'aiCreditTier': aiCreditTier,
        if (tier != null && tier.isNotEmpty) 'tier': tier,
      };

      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Plan created successfully');
          return data['data'];
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to create plan');
    } catch (e) {
      print('[SUBSCRIPTION] createPlan error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePlan({
    required String planId,
    String? displayName,
    String? description,
    double? monthlyPrice,
    String? category,
    List<String>? features,
    int? maxOffers,
    int? maxPhotosPerOffer,
    bool? analyticsEnabled,
    bool? prioritySupport,
    int? sortOrder,
    bool? isActive,
    String? priceChangeReason,
    int? monthlyAiLimit,
    String? rankingTier,
    bool? homepageRotation,
    bool? aiOptimizationSuggestions,
    String? aiCreditTier,
    String? tier,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/plans/$planId',
      );
      print('[SUBSCRIPTION] Updating plan: $planId');

      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (description != null) body['description'] = description;
      if (monthlyPrice != null) body['monthlyPrice'] = monthlyPrice;
      if (category != null) body['category'] = category;
      if (features != null) body['features'] = features;
      if (maxOffers != null) body['maxOffers'] = maxOffers;
      if (maxPhotosPerOffer != null)
        body['maxPhotosPerOffer'] = maxPhotosPerOffer;
      if (analyticsEnabled != null) body['analyticsEnabled'] = analyticsEnabled;
      if (prioritySupport != null) body['prioritySupport'] = prioritySupport;
      if (sortOrder != null) body['sortOrder'] = sortOrder;
      if (isActive != null) body['isActive'] = isActive;
      if (priceChangeReason != null)
        body['priceChangeReason'] = priceChangeReason;
      if (monthlyAiLimit != null) body['monthlyAiLimit'] = monthlyAiLimit;
      if (rankingTier != null) body['rankingTier'] = rankingTier;
      if (homepageRotation != null) body['homepageRotation'] = homepageRotation;
      if (aiOptimizationSuggestions != null)
        body['aiOptimizationSuggestions'] = aiOptimizationSuggestions;
      if (aiCreditTier != null) body['aiCreditTier'] = aiCreditTier;
      if (tier != null) body['tier'] = tier;

      final response = await _client.patch(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Plan updated successfully');
          return data['data'];
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update plan');
    } catch (e) {
      print('[SUBSCRIPTION] updatePlan error: $e');
      rethrow;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/plans/$planId',
      );
      print('[SUBSCRIPTION] Deleting plan: $planId');

      final response = await _client.delete(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Plan deleted successfully');
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to delete plan');
    } catch (e) {
      print('[SUBSCRIPTION] deletePlan error: $e');
      rethrow;
    }
  }

  // ============ AI Credit Packs (Admin) ============

  Future<List<Map<String, dynamic>>> getAiCreditPacks({bool? isActive, String? category}) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/ai-credit-packs',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await _client.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      throw Exception('Failed to fetch AI credit packs');
    } catch (e) {
      print('[SUBSCRIPTION] getAiCreditPacks error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAiCreditPack({
    required String displayName,
    required String category,
    required int credits,
    required double priceSilver,
    required double priceGold,
    required double pricePlatinum,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/ai-credit-packs',
      );
      final body = {
        'displayName': displayName.trim(),
        'category': category.trim().toLowerCase(),
        'credits': credits,
        'priceSilver': priceSilver,
        'priceGold': priceGold,
        'pricePlatinum': pricePlatinum,
        'sortOrder': sortOrder,
        'isActive': isActive,
      };
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>;
      }
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to create pack');
    } catch (e) {
      print('[SUBSCRIPTION] createAiCreditPack error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAiCreditPack({
    required String packId,
    String? displayName,
    String? category,
    int? credits,
    double? priceSilver,
    double? priceGold,
    double? pricePlatinum,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/ai-credit-packs/$packId',
      );
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (category != null) body['category'] = category;
      if (credits != null) body['credits'] = credits;
      if (priceSilver != null) body['priceSilver'] = priceSilver;
      if (priceGold != null) body['priceGold'] = priceGold;
      if (pricePlatinum != null) body['pricePlatinum'] = pricePlatinum;
      if (sortOrder != null) body['sortOrder'] = sortOrder;
      if (isActive != null) body['isActive'] = isActive;
      final response = await _client.patch(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>;
      }
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to update pack');
    } catch (e) {
      print('[SUBSCRIPTION] updateAiCreditPack error: $e');
      rethrow;
    }
  }

  Future<void> deleteAiCreditPack(String packId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/ai-credit-packs/$packId',
      );
      final response = await _client.delete(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return;
      }
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to deactivate pack');
    } catch (e) {
      print('[SUBSCRIPTION] deleteAiCreditPack error: $e');
      rethrow;
    }
  }

  // ============ Subscriptions Management ============

  Future<Map<String, dynamic>> getAllSubscriptions({
    String? status,
    String? planId,
    String? shopkeeperId,
    bool? expiringSoon,
    String? city,
    String? pincode,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (planId != null) queryParams['planId'] = planId;
      if (shopkeeperId != null) queryParams['shopkeeperId'] = shopkeeperId;
      if (expiringSoon != null)
        queryParams['expiringSoon'] = expiringSoon.toString();
      if (city != null && city.trim().isNotEmpty) queryParams['city'] = city.trim();
      if (pincode != null && pincode.trim().isNotEmpty) queryParams['pincode'] = pincode.trim();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/subscriptions',
      ).replace(queryParameters: queryParams);

      print('[SUBSCRIPTION] Fetching subscriptions: $uri');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Fetched subscriptions');
          return data['data'];
        }
      }

      throw Exception('Failed to fetch subscriptions');
    } catch (e) {
      print('[SUBSCRIPTION] getAllSubscriptions error: $e');
      rethrow;
    }
  }

  Future<void> cancelSubscription(String subscriptionId, String reason) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/subscriptions/$subscriptionId/cancel',
      );
      print('[SUBSCRIPTION] Cancelling subscription: $subscriptionId');

      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Subscription cancelled successfully');
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to cancel subscription');
    } catch (e) {
      print('[SUBSCRIPTION] cancelSubscription error: $e');
      rethrow;
    }
  }

  Future<void> renewSubscription({
    required String subscriptionId,
    int durationMonths = 1,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/subscriptions/$subscriptionId/renew',
      );
      print('[SUBSCRIPTION] Renewing subscription: $subscriptionId');

      final body = {
        'durationMonths': durationMonths,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
      };

      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Subscription renewed successfully');
          return;
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to renew subscription');
    } catch (e) {
      print('[SUBSCRIPTION] renewSubscription error: $e');
      rethrow;
    }
  }

  // ============ Analytics ============

  Future<Map<String, dynamic>> getMonitoringDashboard() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/monitoring/dashboard',
      );
      print('[SUBSCRIPTION] Fetching monitoring dashboard');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Fetched monitoring dashboard');
          return data['data'];
        }
      }

      throw Exception('Failed to fetch monitoring dashboard');
    } catch (e) {
      print('[SUBSCRIPTION] getMonitoringDashboard error: $e');
      rethrow;
    }
  }

  /// Filterable subscription metrics (by pincode / city / category / status, grouped by tier).
  Future<Map<String, dynamic>> getSubscriptionMetrics({
    String status = 'active',
    String? pincode,
    String? city,
    String? category,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/analytics/subscription-metrics',
      ).replace(queryParameters: {
        'status': status,
        if (pincode != null && pincode.trim().isNotEmpty) 'pincode': pincode.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      });

      print(
          '[SUBSCRIPTION] Fetching subscription metrics with status=$status, pincode=$pincode, city=$city, category=$category');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Fetched subscription metrics');
          return data['data'];
        }
      }

      throw Exception('Failed to fetch subscription metrics');
    } catch (e) {
      print('[SUBSCRIPTION] getSubscriptionMetrics error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRevenueIntelligence() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/subscription-governance/intelligence/revenue',
      );
      print('[SUBSCRIPTION] Fetching revenue intelligence');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('[SUBSCRIPTION] Fetched revenue intelligence');
          return data['data'];
        }
      }

      throw Exception('Failed to fetch revenue intelligence');
    } catch (e) {
      print('[SUBSCRIPTION] getRevenueIntelligence error: $e');
      rethrow;
    }
  }

  // ============ Shopkeeper Plans (Category-based) ============

  Future<List<Map<String, dynamic>>> getRecommendedPlans(
      String category) async {
    try {
      // Use shopkeeper endpoint, not governance endpoint
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/shopkeeper/plans/recommend',
      ).replace(queryParameters: {'category': category});

      print(
          '[SUBSCRIPTION] Fetching recommended plans for category: $category');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final plans = List<Map<String, dynamic>>.from(data['data']);
          print('[SUBSCRIPTION] Fetched ${plans.length} recommended plans');
          return plans;
        }
      }

      throw Exception('Failed to fetch recommended plans');
    } catch (e) {
      print('[SUBSCRIPTION] getRecommendedPlans error: $e');
      rethrow;
    }
  }

  // ============ Shopkeeper Subscription ============

  Future<Map<String, dynamic>> getSubscription() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/subscription');
      print('[SUBSCRIPTION] Fetching shopkeeper subscription');

      final response = await _client.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['subscription'] as Map<String, dynamic>;
        }
      }

      throw Exception('Failed to fetch subscription status');
    } catch (e) {
      print('[SUBSCRIPTION] getSubscription error: $e');
      rethrow;
    }
  }

  /// Get a price quote for a plan + optional coupon (discount and attribution).
  Future<Map<String, dynamic>> getQuote({
    required String? planId,
    String? planType,
    required int durationMonths,
    String? couponCode,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/subscription/quote');
      final body = <String, dynamic>{
        'durationMonths': durationMonths,
        if (planId != null) 'planId': planId,
        if (planType != null) 'planType': planType,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'couponCode': couponCode.trim(),
      };
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['quote'] != null) {
          return data['quote'] as Map<String, dynamic>;
        }
      }
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? 'Failed to get quote');
    } catch (e) {
      print('[SUBSCRIPTION] getQuote error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> activateSubscription({
    required String planId,
    required int durationMonths,
    required String paymentMethod,
    String? transactionId,
    String? couponCode,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/subscription/activate');
      print('[SUBSCRIPTION] Activating subscription');

      final body = {
        'planId': planId,
        'durationMonths': durationMonths,
        'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'couponCode': couponCode.trim(),
      };

      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['subscription'] as Map<String, dynamic>;
        }
      }

      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Failed to activate subscription');
    } catch (e) {
      print('[SUBSCRIPTION] activateSubscription error: $e');
      rethrow;
    }
  }

  // ============ Shopkeeper AI Wallet & Packs ============

  Future<Map<String, dynamic>> getAiWallet() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shopkeeper/ai-wallet');
      final response = await _client.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch AI wallet');
    } catch (e) {
      print('[SUBSCRIPTION] getAiWallet error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAiCreditPacksForShopkeeper() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shopkeeper/ai-credits/packs');
      final response = await _client.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      throw Exception('Failed to fetch AI credit packs');
    } catch (e) {
      print('[SUBSCRIPTION] getAiCreditPacksForShopkeeper error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> purchaseAiCreditPack({
    required String packSku,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shopkeeper/ai-credits/purchase');
      final body = {
        'packSku': packSku,
        'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
      };
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return data['data'] as Map<String, dynamic>;
      }
      final err = jsonDecode(response.body);
      if (response.statusCode == 403 &&
          (err['code']?.toString() == 'AI_LIMIT_REACHED')) {
        throw AiLimitReachedException();
      }
      throw Exception(err['message'] ?? 'Failed to purchase pack');
    } catch (e) {
      print('[SUBSCRIPTION] purchaseAiCreditPack error: $e');
      rethrow;
    }
  }

  /// Call before or when using an AI banner. Deducts 1 credit; throws
  /// [AiLimitReachedException] if no credits available.
  Future<void> useAiBanner() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shopkeeper/ai-banners/use');
      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return;
      final err = jsonDecode(response.body);
      if (response.statusCode == 403 &&
          (err['code']?.toString() == 'AI_LIMIT_REACHED')) {
        throw AiLimitReachedException();
      }
      throw Exception(err['message'] ?? 'Failed to use AI banner');
    } catch (e) {
      print('[SUBSCRIPTION] useAiBanner error: $e');
      rethrow;
    }
  }
}
