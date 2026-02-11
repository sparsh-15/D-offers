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
  });

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
    );
  }
}

