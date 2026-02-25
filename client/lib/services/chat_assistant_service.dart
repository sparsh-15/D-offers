import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_store.dart';

class ChatAssistantAction {
  final String label;
  final String type;
  final Map<String, dynamic> payload;

  ChatAssistantAction({
    required this.label,
    required this.type,
    required this.payload,
  });

  factory ChatAssistantAction.fromJson(Map<String, dynamic> json) {
    return ChatAssistantAction(
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json)..removeWhere(
          (key, _) => key == 'label' || key == 'type',
        ),
    );
  }
}

class ChatAssistantResult {
  final String reply;
  final List<ChatAssistantAction> actions;
  final Map<String, dynamic> items;

  ChatAssistantResult({
    required this.reply,
    required this.actions,
    required this.items,
  });
}

class ChatAssistantService {
  ChatAssistantService._();

  static final ChatAssistantService instance = ChatAssistantService._();

  Future<ChatAssistantResult> sendMessage(String message) async {
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

      final rawActions = data?['actions'];
      final actions = <ChatAssistantAction>[];
      if (rawActions is List) {
        for (final a in rawActions) {
          if (a is Map<String, dynamic>) {
            actions.add(ChatAssistantAction.fromJson(a));
          }
        }
      }

      final items = (data?['items'] is Map<String, dynamic>)
          ? Map<String, dynamic>.from(data!['items'] as Map)
          : <String, dynamic>{};

      return ChatAssistantResult(
        reply: reply,
        actions: actions,
        items: items,
      );
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

