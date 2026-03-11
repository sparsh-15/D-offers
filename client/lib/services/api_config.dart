import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API Configuration for Node/Express backend (port 3000, /api prefix)
class ApiConfig {
  /// Toggle between environments
  /// Set to false for local development
  /// Set to true for production/deployed backend
  static const bool useProduction = false;

  /// Your machine's IP on the local network. Used for physical device & iOS.
  /// - Physical Android/iOS on same Wi‑Fi: use this (e.g. 192.168.29.47).
  /// - Android emulator: use '10.0.2.2' to reach host.
  /// Find your IP: Windows `ipconfig`, Mac/Linux `ifconfig` or `ip addr`.
  static const String devHost = '10.63.200.228';

  static String get baseUrl {
    if (useProduction) {
      return 'https://d-offers.onrender.com/api';
    } else {
      if (kIsWeb) return 'http://localhost:3000/api';
      try {
        if (Platform.isAndroid) {
          // Use devHost for both emulator (10.0.2.2) and physical device (your LAN IP)
          return 'http://$devHost:3000/api';
        } else {
          return 'http://$devHost:3000/api';
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
  static String get companySalesUrl => '$baseUrl/company-sales';
}
