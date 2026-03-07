import 'role_enum.dart';

UserRole roleFromString(String value) {
  switch (value) {
    case 'super_admin':
    case 'subadmin':
    case 'admin': // backward compatibility
      return UserRole.admin;
    case 'company_sales_agent':
      return UserRole.companySalesAgent;
    case 'ssa':
      return UserRole.ssa;
    case 'customer':
      return UserRole.customer;
    case 'shopkeeper':
      return UserRole.shopkeeper;
    default:
      return UserRole.customer;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'super_admin';
    case UserRole.companySalesAgent:
      return 'company_sales_agent';
    case UserRole.ssa:
      return 'ssa';
    case UserRole.customer:
      return 'customer';
    case UserRole.shopkeeper:
      return 'shopkeeper';
  }
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String pincode;
  final String city;
  final String state;
  final String address;
  final String approvalStatus; // legacy: pending | approved | rejected
  final String statusLabel; // derived: subscribed | active | inactive | setup_pending
  final String category; // optional: from shopkeeperProfile.category for shopkeepers
  final String? signupCouponCode; // optional referral coupon captured at registration (shopkeeper)

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.pincode,
    required this.city,
    required this.state,
    required this.address,
    required this.approvalStatus,
    required this.statusLabel,
    this.category = '',
    this.signupCouponCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['shopkeeperProfile'] as Map<String, dynamic>?;
    final categoryFromProfile =
        profile?['category']?.toString() ?? json['category']?.toString() ?? '';
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: roleFromString(json['role']?.toString() ?? 'customer'),
      pincode: json['pincode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      approvalStatus: json['approvalStatus']?.toString() ?? '',
      statusLabel: (json['statusLabel']?.toString() ??
              json['approvalStatus']?.toString() ??
              '')
          .toLowerCase(),
      category: categoryFromProfile,
      signupCouponCode: json['signupCouponCode']?.toString(),
    );
  }

  // Get display name for role
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.companySalesAgent:
        return 'SALES AGENT';
      case UserRole.ssa:
        return 'SSA';
      case UserRole.shopkeeper:
        return 'SHOPKEEPER';
      case UserRole.customer:
        return 'CUSTOMER';
    }
  }
}
