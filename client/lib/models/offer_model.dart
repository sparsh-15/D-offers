class OfferModel {
  final String id;
  final String shopkeeperId;
  final String title;
  final String description;
  final String discountType;
  final dynamic discountValue;
  final DateTime? validFrom;
  final DateTime? validTo;
  final String status;
  final int likesCount;
  final bool isLiked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OfferModel({
    required this.id,
    required this.shopkeeperId,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.likesCount,
    this.isLiked = false,
    this.createdAt,
    this.updatedAt,
  });

  OfferModel copyWith({
    String? id,
    String? shopkeeperId,
    String? title,
    String? description,
    String? discountType,
    dynamic discountValue,
    DateTime? validFrom,
    DateTime? validTo,
    String? status,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OfferModel(
      id: id ?? this.id,
      shopkeeperId: shopkeeperId ?? this.shopkeeperId,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      shopkeeperId: json['shopkeeperId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? '',
      discountValue: json['discountValue'],
      validFrom: json['validFrom'] != null ? DateTime.tryParse(json['validFrom'].toString()) : null,
      validTo: json['validTo'] != null ? DateTime.tryParse(json['validTo'].toString()) : null,
      status: json['status']?.toString() ?? '',
      likesCount: int.tryParse(json['likesCount']?.toString() ?? '0') ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }
}

