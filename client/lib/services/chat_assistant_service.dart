import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';

class ChatAssistantService {
  ChatAssistantService._();

  static final ChatAssistantService instance = ChatAssistantService._();

  Future<String> sendMessage(String message) async {
    final token = AuthStore.token;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/ai/chat');

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{'message': message}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      final reply = data?['reply']?.toString();
      if (reply == null || reply.trim().isEmpty) {
        throw Exception('Empty reply from assistant');
      }
      return reply;
    }

    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // ignore JSON parse errors
    }
    final messageFromServer = errorBody?['message']?.toString();
    throw Exception(messageFromServer ?? 'Failed to contact assistant');
  }
}

