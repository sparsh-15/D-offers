class RedemptionCouponSummary {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;

  const RedemptionCouponSummary({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
  });

  factory RedemptionCouponSummary.fromJson(Map<String, dynamic> json) {
    return RedemptionCouponSummary(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountValue:
          double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0,
    );
  }
}

class RedemptionOfferSummary {
  final String id;
  final String title;
  final String shopkeeperId;

  const RedemptionOfferSummary({
    required this.id,
    required this.title,
    required this.shopkeeperId,
  });

  factory RedemptionOfferSummary.fromJson(Map<String, dynamic> json) {
    return RedemptionOfferSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shopkeeperId: json['shopkeeperId']?.toString() ?? '',
    );
  }
}

class RedemptionActorSummary {
  final String id;
  final String name;
  final String phone;
  final String role;

  const RedemptionActorSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory RedemptionActorSummary.fromJson(Map<String, dynamic> json) {
    return RedemptionActorSummary(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
    );
  }
}

class RedemptionVerificationData {
  final RedemptionCouponSummary coupon;
  final RedemptionOfferSummary offer;

  const RedemptionVerificationData({
    required this.coupon,
    required this.offer,
  });

  factory RedemptionVerificationData.fromJson(Map<String, dynamic> json) {
    return RedemptionVerificationData(
      coupon: RedemptionCouponSummary.fromJson(
        Map<String, dynamic>.from(json['coupon'] as Map? ?? const {}),
      ),
      offer: RedemptionOfferSummary.fromJson(
        Map<String, dynamic>.from(json['offer'] as Map? ?? const {}),
      ),
    );
  }
}

class RedemptionRecord {
  final String id;
  final String status;
  final String verificationMethod;
  final DateTime? redeemedAt;
  final RedemptionCouponSummary coupon;
  final RedemptionOfferSummary offer;
  final RedemptionActorSummary redeemedBy;

  const RedemptionRecord({
    required this.id,
    required this.status,
    required this.verificationMethod,
    required this.redeemedAt,
    required this.coupon,
    required this.offer,
    required this.redeemedBy,
  });

  factory RedemptionRecord.fromJson(Map<String, dynamic> json) {
    return RedemptionRecord(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      verificationMethod: json['verificationMethod']?.toString() ?? 'manual',
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.tryParse(json['redeemedAt'].toString())
          : null,
      coupon: RedemptionCouponSummary.fromJson(
        Map<String, dynamic>.from(json['coupon'] as Map? ?? const {}),
      ),
      offer: RedemptionOfferSummary.fromJson(
        Map<String, dynamic>.from(json['offer'] as Map? ?? const {}),
      ),
      redeemedBy: RedemptionActorSummary.fromJson(
        Map<String, dynamic>.from(json['redeemedBy'] as Map? ?? const {}),
      ),
    );
  }
}

class RedemptionResponse {
  final String result;
  final String message;
  final RedemptionVerificationData? verification;
  final RedemptionRecord? redemption;
  final bool idempotentReplay;

  const RedemptionResponse({
    required this.result,
    required this.message,
    this.verification,
    this.redemption,
    this.idempotentReplay = false,
  });

  factory RedemptionResponse.fromJson(Map<String, dynamic> json) {
    final verification = json['verification'] is Map
        ? RedemptionVerificationData.fromJson(
            Map<String, dynamic>.from(json['verification'] as Map),
          )
        : null;

    final redemption = json['redemption'] is Map
        ? RedemptionRecord.fromJson(
            Map<String, dynamic>.from(json['redemption'] as Map),
          )
        : null;

    return RedemptionResponse(
      result: json['result']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? '',
      verification: verification,
      redemption: redemption,
      idempotentReplay: json['idempotentReplay'] == true,
    );
  }
}

class RedemptionHistoryPage {
  final List<RedemptionRecord> items;
  final int offset;
  final int limit;
  final int total;
  final bool hasMore;
  final int? nextOffset;

  const RedemptionHistoryPage({
    required this.items,
    required this.offset,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.nextOffset,
  });

  factory RedemptionHistoryPage.fromJson(Map<String, dynamic> json) {
    final items = List<Map<String, dynamic>>.from(
      json['redemptions'] as List? ?? const [],
    ).map(RedemptionRecord.fromJson).toList();

    final pageInfo = Map<String, dynamic>.from(
      json['pageInfo'] as Map? ?? const {},
    );

    return RedemptionHistoryPage(
      items: items,
      offset: int.tryParse(pageInfo['offset']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(pageInfo['limit']?.toString() ?? '20') ?? 20,
      total: int.tryParse(pageInfo['total']?.toString() ?? '0') ?? 0,
      hasMore: pageInfo['hasMore'] == true,
      nextOffset: pageInfo['nextOffset'] == null
          ? null
          : int.tryParse(pageInfo['nextOffset'].toString()),
    );
  }
}
