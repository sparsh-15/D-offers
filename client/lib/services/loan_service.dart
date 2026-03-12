import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';

class LoanService {
  LoanService._() {
    HttpOverrides.global = _MyHttpOverrides();
  }

  static final LoanService instance = LoanService._();

  final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 30);

  Future<http.Response> _makeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on SocketException catch (e) {
      throw Exception(
          'Network error: Please check your internet connection. ${e.message}');
    } on TimeoutException catch (_) {
      throw Exception('Request timeout: Server is taking too long to respond');
    } on http.ClientException catch (e) {
      throw Exception('Connection error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Submit a new loan application
  Future<LoanApplicationResponse> submitLoanApplication({
    required String fullName,
    required String mobileNumber,
    required String employmentType,
    required String monthlySalaryIncome,
    required String loanAmount,
    required String panNumber,
    required String bankName,
    required String accountType,
    required String last4AccountDigits,
    required bool cibilConsent,
    required bool communicationConsent,
  }) async {
    try {
      final token = AuthStore.token;

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final response = await _makeRequest(() async {
        return await _client.post(
          Uri.parse('${ApiConfig.baseUrl}/customer/loans/apply'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'fullName': fullName,
            'mobileNumber': mobileNumber,
            'employmentType': employmentType,
            'monthlySalaryIncome': monthlySalaryIncome,
            'loanAmount': loanAmount,
            'panNumber': panNumber,
            'bankName': bankName,
            'accountType': accountType,
            'last4AccountDigits': last4AccountDigits,
            'cibilConsent': cibilConsent,
            'communicationConsent': communicationConsent,
          }),
        );
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return LoanApplicationResponse.fromJson(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit loan application');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get all loan applications for the current user
  Future<List<LoanApplication>> getLoanApplications({
    int limit = 10,
    int skip = 0,
  }) async {
    try {
      final token = AuthStore.token;

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final response = await _makeRequest(() async {
        return await _client.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/customer/loans?limit=$limit&skip=$skip',
          ),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final applications = (data['data'] as List)
            .map((e) => LoanApplication.fromJson(e))
            .toList();
        return applications;
      } else {
        throw Exception('Failed to fetch loan applications');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get a specific loan application by ID
  Future<LoanApplication> getLoanApplicationById(String id) async {
    try {
      final token = AuthStore.token;

      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final response = await _makeRequest(() async {
        return await _client.get(
          Uri.parse('${ApiConfig.baseUrl}/customer/loans/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoanApplication.fromJson(data['data']);
      } else {
        throw Exception('Failed to fetch loan application');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Response model for loan application submission
class LoanApplicationResponse {
  final bool success;
  final String message;
  final String loanApplicationId;
  final DateTime createdAt;

  LoanApplicationResponse({
    required this.success,
    required this.message,
    required this.loanApplicationId,
    required this.createdAt,
  });

  factory LoanApplicationResponse.fromJson(Map<String, dynamic> json) {
    return LoanApplicationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      loanApplicationId: json['data']['id'] ?? '',
      createdAt: DateTime.parse(json['data']['createdAt']),
    );
  }
}

// Model for loan application data
class LoanApplication {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String employmentType;
  final String monthlySalaryIncome;
  final String loanAmount;
  final String panNumber;
  final String bankName;
  final String accountType;
  final String last4AccountDigits;
  final bool cibilConsent;
  final bool communicationConsent;
  final String status;
  final int? cibilScore;
  final String? eligibilityStatus;
  final DateTime createdAt;
  final DateTime? evaluatedAt;

  LoanApplication({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    required this.employmentType,
    required this.monthlySalaryIncome,
    required this.loanAmount,
    required this.panNumber,
    required this.bankName,
    required this.accountType,
    required this.last4AccountDigits,
    required this.cibilConsent,
    required this.communicationConsent,
    required this.status,
    this.cibilScore,
    this.eligibilityStatus,
    required this.createdAt,
    this.evaluatedAt,
  });

  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      employmentType: json['employmentType'] ?? '',
      monthlySalaryIncome: json['monthlySalaryIncome']?.toString() ?? '0',
      loanAmount: json['loanAmount']?.toString() ?? '0',
      panNumber: json['panNumber'] ?? '',
      bankName: json['bankName'] ?? '',
      accountType: json['accountType'] ?? '',
      last4AccountDigits: json['last4AccountDigits'] ?? '',
      cibilConsent: json['cibilConsent'] ?? false,
      communicationConsent: json['communicationConsent'] ?? false,
      status: json['status'] ?? 'pending',
      cibilScore: json['cibilScore'],
      eligibilityStatus: json['eligibilityStatus'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toString()),
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.parse(json['evaluatedAt'])
          : null,
    );
  }
}

// Custom HTTP override for SSL certificates
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) =>
          true;
  }
}
