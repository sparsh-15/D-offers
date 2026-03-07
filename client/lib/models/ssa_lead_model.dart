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
  final String? inviteStatus;
  final String? inviteError;
  final DateTime? inviteSentAt;
  final DateTime? claimedAt;
  final String? linkedUserId;
  final String? resultType;
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
    this.inviteStatus,
    this.inviteError,
    this.inviteSentAt,
    this.claimedAt,
    this.linkedUserId,
    this.resultType,
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
      inviteStatus: json['inviteStatus']?.toString(),
      inviteError: json['inviteError']?.toString(),
      inviteSentAt: json['inviteSentAt'] != null
          ? DateTime.tryParse(json['inviteSentAt'].toString())
          : null,
      claimedAt: json['claimedAt'] != null
          ? DateTime.tryParse(json['claimedAt'].toString())
          : null,
      linkedUserId: json['linkedUserId']?.toString(),
      resultType: json['resultType']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

