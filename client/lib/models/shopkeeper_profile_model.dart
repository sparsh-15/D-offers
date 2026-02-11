class ShopkeeperProfileModel {
  final String id;
  final String userId;
  final String shopName;
  final String address;
  final String pincode;
  final String city;
  final String category;
  final String description;

  ShopkeeperProfileModel({
    required this.id,
    required this.userId,
    required this.shopName,
    required this.address,
    required this.pincode,
    required this.city,
    required this.category,
    required this.description,
  });

  factory ShopkeeperProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopkeeperProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

