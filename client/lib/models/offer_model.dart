class OfferModel {
  final String id;
  final String shopkeeperId;
  final String? shopName;
  final String? shopLogoUrl;
  final String title;
  final String description;
  final List<String> photos;
  final String termsAndConditions;
  final String category;
  final String discountType;
  final dynamic discountValue;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String status;
  final int likesCount;
  final bool isLiked;
  final bool isClaimed;
  final String shopRankingTier;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.shopkeeperId,
    this.shopName,
    this.shopLogoUrl,
    required this.title,
    required this.description,
    this.photos = const [],
    this.termsAndConditions = '',
    this.category = '',
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.likesCount,
    this.isLiked = false,
    this.isClaimed = false,
    this.shopRankingTier = 'normal',
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  OfferModel copyWith({
    String? id,
    String? shopkeeperId,
    String? shopName,
    String? shopLogoUrl,
    String? title,
    String? description,
    List<String>? photos,
    String? termsAndConditions,
    String? category,
    String? discountType,
    dynamic discountValue,
    DateTime? validFrom,
    DateTime? validTo,
    String? status,
    int? likesCount,
    bool? isLiked,
    bool? isClaimed,
    String? shopRankingTier,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      shopkeeperId: shopkeeperId ?? this.shopkeeperId,
      shopName: shopName ?? this.shopName,
      shopLogoUrl: shopLogoUrl ?? this.shopLogoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      category: category ?? this.category,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      isClaimed: isClaimed ?? this.isClaimed,
      shopRankingTier: shopRankingTier ?? this.shopRankingTier,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      shopkeeperId: json['shopkeeperId']?.toString() ?? '',
      shopName: json['shopName']?.toString(),
      shopLogoUrl:
          json['shopLogoUrl']?.toString() ?? json['logoUrl']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      photos: json['photos'] != null
          ? (json['photos'] as List).map((e) => e.toString()).toList()
          : [],
      termsAndConditions: json['termsAndConditions']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      discountValue: json['discountValue'],
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'].toString())
          : null,
      validTo: json['validTo'] != null
          ? DateTime.tryParse(json['validTo'].toString())
          : null,
      status: json['status']?.toString() ?? '',
      likesCount: int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      shopRankingTier: json['shopRankingTier']?.toString() ?? 'normal',
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
