import '../models/user_model.dart';

class AuthStore {
  static String? token;
  static UserModel? currentUser;

  static void clear() {
    token = null;
    currentUser = null;
  }
}

