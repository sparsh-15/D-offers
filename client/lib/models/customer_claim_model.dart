class CustomerClaimOfferSummary {
  final String id;
  final String title;
  final String shopkeeperId;
  final DateTime? validTo;
  final String discountType;
  final double discountValue;

  const CustomerClaimOfferSummary({
    required this.id,
    required this.title,
    required this.shopkeeperId,
    required this.validTo,
    required this.discountType,
    required this.discountValue,
  });

  factory CustomerClaimOfferSummary.fromJson(Map<String, dynamic> json) {
    return CustomerClaimOfferSummary(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shopkeeperId: json['shopkeeperId']?.toString() ?? '',
      validTo: json['validTo'] != null ? DateTime.tryParse(json['validTo'].toString()) : null,
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0,
    );
  }
}

class CustomerClaimCouponSummary {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final DateTime? expiryDate;
  final int? maxUses;
  final int currentUses;

  const CustomerClaimCouponSummary({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.expiryDate,
    required this.maxUses,
    required this.currentUses,
  });

  factory CustomerClaimCouponSummary.fromJson(Map<String, dynamic> json) {
    return CustomerClaimCouponSummary(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'percentage',
      discountValue: double.tryParse(json['discountValue']?.toString() ?? '0') ?? 0,
      expiryDate:
          json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      maxUses: json['maxUses'] == null ? null : int.tryParse(json['maxUses'].toString()),
      currentUses: int.tryParse(json['currentUses']?.toString() ?? '0') ?? 0,
    );
  }
}

class CustomerClaim {
  final String id;
  final String status;
  final DateTime? claimedAt;
  final DateTime? redeemedAt;
  final DateTime? expiresAt;
  final String qrPayload;
  final CustomerClaimOfferSummary offer;
  final CustomerClaimCouponSummary coupon;

  const CustomerClaim({
    required this.id,
    required this.status,
    required this.claimedAt,
    required this.redeemedAt,
    required this.expiresAt,
    required this.qrPayload,
    required this.offer,
    required this.coupon,
  });

  bool get isRedeemed => status.toLowerCase() == 'redeemed';
  bool get isActive => status.toLowerCase() == 'active';
  bool get isExpired => status.toLowerCase() == 'expired';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Returns days remaining until expiry, or null if already expired/no expiry.
  int? get daysUntilExpiry {
    if (expiresAt == null || isRedeemed) return null;
    final now = DateTime.now();
    if (expiresAt!.isBefore(now)) return null;
    return expiresAt!.difference(now).inDays;
  }

  /// Human-readable expiry string (e.g., "Expires in 5 days" or "Expires soon").
  String get expiryDisplayText {
    if (isRedeemed) return 'Redeemed';
    if (isExpired) return 'Expired';
    if (isCancelled) return 'Cancelled';
    final days = daysUntilExpiry;
    if (days == null) return 'Expiry unknown';
    if (days >= 10) return 'Expires in $days days';
    if (days > 1) return 'Expires in $days days';
    if (days == 1) return 'Expires tomorrow';
    return 'Expires today';
  }

  factory CustomerClaim.fromJson(Map<String, dynamic> json) {
    return CustomerClaim(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'].toString()) : null,
      redeemedAt:
          json['redeemedAt'] != null ? DateTime.tryParse(json['redeemedAt'].toString()) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
      qrPayload: json['qrPayload']?.toString() ?? '',
      offer: CustomerClaimOfferSummary.fromJson(
        Map<String, dynamic>.from(json['offer'] as Map? ?? const {}),
      ),
      coupon: CustomerClaimCouponSummary.fromJson(
        Map<String, dynamic>.from(json['coupon'] as Map? ?? const {}),
      ),
    );
  }
}

class CustomerClaimsPage {
  final List<CustomerClaim> items;
  final int offset;
  final int limit;
  final int total;
  final bool hasMore;
  final int? nextOffset;

  const CustomerClaimsPage({
    required this.items,
    required this.offset,
    required this.limit,
    required this.total,
    required this.hasMore,
    required this.nextOffset,
  });

  factory CustomerClaimsPage.fromJson(Map<String, dynamic> json) {
    final claims = List<Map<String, dynamic>>.from(
      json['claims'] as List? ?? const [],
    ).map(CustomerClaim.fromJson).toList();

    final pageInfo = Map<String, dynamic>.from(
      json['pageInfo'] as Map? ?? const {},
    );

    return CustomerClaimsPage(
      items: claims,
      offset: int.tryParse(pageInfo['offset']?.toString() ?? '0') ?? 0,
      limit: int.tryParse(pageInfo['limit']?.toString() ?? '20') ?? 20,
      total: int.tryParse(pageInfo['total']?.toString() ?? '0') ?? 0,
      hasMore: pageInfo['hasMore'] == true,
      nextOffset:
          pageInfo['nextOffset'] == null ? null : int.tryParse(pageInfo['nextOffset'].toString()),
    );
  }
}
