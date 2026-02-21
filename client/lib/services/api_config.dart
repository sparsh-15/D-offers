import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API Configuration for Node/Express backend (port 3000, /api prefix)
class ApiConfig {
  /// Toggle between environments
  /// Set to false for local development
  /// Set to true for production/deployed backend
  ///
  static const bool useProduction = true;

  static String get baseUrl {
    if (useProduction) {
      // TODO: set your deployed Node backend URL, e.g. https://api.doffers.com/api
      return 'https://d-offers.onrender.com/api';
    } else {
      // Local Node backend on port 3000 with /api prefix
      if (kIsWeb) return 'http://localhost:3000/api';
      try {
        if (Platform.isAndroid) {
          // Android emulator talks to host via 10.0.2.2
          return 'http://10.0.2.2:3000/api';
        } else {
          return 'http://localhost:3000/api'; // iOS simulator / physical on same machine
        }
      } catch (_) {
        return 'http://localhost:3000/api';
      }
    }
  }

  // Endpoints
  static String get authUrl => '$baseUrl/auth';
  static String get shopkeeperUrl => '$baseUrl/shopkeeper';
  static String get adminUrl => '$baseUrl/admin';
  static String get metaUrl => '$baseUrl/meta';
}
