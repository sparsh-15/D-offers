enum UserRole {
  admin,
  customer,
  shopkeeper,
}

UserRole roleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
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
      return 'admin';
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
  final String approvalStatus; // pending | approved | rejected

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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

