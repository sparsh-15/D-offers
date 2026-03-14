class ShopkeeperProfileModel {
  final String id;
  final String userId;
  final String shopName;
  final String address;
  final String pincode;
  final String city;
  final double? latitude;
  final double? longitude;
  final String category;
  final String description;
  final List<String> shopImages;
  final String? logoUrl;
  final String? ownerName;
  final String? ownerPhone;

  static double? _parseCoordinate(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  ShopkeeperProfileModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.address,
    required this.pincode,
    required this.city,
    this.latitude,
    this.longitude,
    required this.category,
    required this.description,
    required this.shopImages,
    this.logoUrl,
    this.ownerName,
    this.ownerPhone,
  });

  factory ShopkeeperProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopkeeperProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
        latitude: _parseCoordinate(json['latitude']),
        longitude: _parseCoordinate(json['longitude']),
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      shopImages: (json['shopImages'] as List<dynamic>? ?? const [])
          .map((image) => image.toString())
          .where((image) => image.isNotEmpty)
          .toList(),
      logoUrl: json['logoUrl']?.toString(),
      ownerName: json['ownerName']?.toString(),
      ownerPhone: json['ownerPhone']?.toString(),
    );
  }
}

