import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeService {
  static final PincodeService instance = PincodeService._();
  PincodeService._();

  // Fetch pincode details using multiple APIs with fallback
  Future<Map<String, dynamic>?> getPincodeDetails(String pincode) async {
    if (pincode.length != 6) {
      throw Exception('Pincode must be 6 digits');
    }

    // Try Zippopotam API first (more reliable)
    try {
      return await _fetchFromZippopotamAPI(pincode);
    } catch (e) {
      // If Zippopotam fails, try India Post API
      try {
        return await _fetchFromPostalAPI(pincode);
      } catch (e2) {
        // Both failed
        throw Exception(
            'Unable to fetch pincode details. Please check the pincode and try again.');
      }
    }
  }

  // Primary API: Zippopotam.us (more reliable, no CORS issues)
  Future<Map<String, dynamic>?> _fetchFromZippopotamAPI(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.zippopotam.us/in/$pincode'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['places'] != null && (data['places'] as List).isNotEmpty) {
          final places = data['places'] as List;
          final firstPlace = places[0];

          // Extract unique place names as areas
          final areas = places
              .map((place) => place['place name'] as String)
              .toSet()
              .toList();

          return {
            'pincode': pincode,
            'state': firstPlace['state'] as String,
            'district': firstPlace['place name'] as String,
            'city': firstPlace['place name'] as String,
            'areas': areas,
            'region': null,
          };
        } else {
          throw Exception('No data found for this pincode');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Pincode not found');
      }

      throw Exception('Failed to fetch from Zippopotam API');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      }
      rethrow;
    }
  }

  // Fallback API: India Post API
  Future<Map<String, dynamic>?> _fetchFromPostalAPI(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.postalpincode.in/pincode/$pincode'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Check if response is HTML (error page)
        final body = response.body.trim();
        if (body.startsWith('<') || body.startsWith('<!')) {
          throw Exception('API returned HTML instead of JSON');
        }

        final data = jsonDecode(body);

        if (data is List && data.isNotEmpty) {
          final result = data[0];

          if (result['Status'] == 'Success' && result['PostOffice'] != null) {
            final postOffices = result['PostOffice'] as List;

            if (postOffices.isNotEmpty) {
              final firstOffice = postOffices[0];

              // Extract unique areas from all post offices
              final areas = postOffices
                  .map((office) => office['Name'] as String)
                  .toSet()
                  .toList();

              return {
                'pincode': pincode,
                'state': firstOffice['State'] as String,
                'district': firstOffice['District'] as String,
                'city': firstOffice['District'] as String,
                'areas': areas,
                'region': firstOffice['Region'] as String?,
              };
            }
          } else {
            throw Exception('Invalid pincode');
          }
        }
      }

      throw Exception('Failed to fetch from Postal API');
    } on FormatException {
      throw Exception('Invalid response format from API');
    } catch (e) {
      rethrow;
    }
  }
}
