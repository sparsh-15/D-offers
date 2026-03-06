class SsaLead {
  final String id;
  final String shopName;
  final String? ownerName;
  final String phone;
  final String? pincode;
  final String? city;
  final String? category;
  final String? notes;
  final String? couponCode;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SsaLead({
    required this.id,
    required this.shopName,
    this.ownerName,
    required this.phone,
    this.pincode,
    this.city,
    this.category,
    this.notes,
    this.couponCode,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory SsaLead.fromJson(Map<String, dynamic> json) {
    return SsaLead(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? '',
      ownerName: json['ownerName']?.toString(),
      phone: json['phone']?.toString() ?? '',
      pincode: json['pincode']?.toString(),
      city: json['city']?.toString(),
      category: json['category']?.toString(),
      notes: json['notes']?.toString(),
      couponCode: json['couponCode']?.toString(),
      status: json['status']?.toString() ?? 'open',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

