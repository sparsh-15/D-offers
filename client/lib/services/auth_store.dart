import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';

class AuthStore {
  static String? token;
  static UserModel? currentUser;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static void clear() {
    token = null;
    currentUser = null;
  }

  static Future<void> saveAuth(String tokenValue, UserModel user) async {
    token = tokenValue;
    currentUser = user;

    final userMap = <String, dynamic>{
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'role': roleToString(user.role),
      'permissions': user.permissions,
      'pincode': user.pincode,
      'city': user.city,
      'state': user.state,
      'address': user.address,
      'approvalStatus': user.approvalStatus,
      'statusLabel': user.statusLabel,
      'category': user.category,
      if (user.signupCouponCode != null)
        'signupCouponCode': user.signupCouponCode,
    };

    await _storage.write(key: _tokenKey, value: tokenValue);
    await _storage.write(key: _userKey, value: jsonEncode(userMap));
  }

  static Future<bool> loadAuth() async {
    try {
      final savedToken = await _storage.read(key: _tokenKey);
      final savedUser = await _storage.read(key: _userKey);

      if (savedToken == null || savedUser == null) {
        return false;
      }

      final decoded = jsonDecode(savedUser) as Map<String, dynamic>;
      token = savedToken;
      currentUser = UserModel.fromJson(decoded);
      return true;
    } catch (_) {
      token = null;
      currentUser = null;
      return false;
    }
  }

  static Future<void> clearPersistedAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

