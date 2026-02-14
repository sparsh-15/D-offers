import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';

/// Simple chat screen with dummy Q&A. Opened from customer dashboard FAB.
class CustomerChatBotScreen extends StatefulWidget {
  const CustomerChatBotScreen({super.key});

  @override
  State<CustomerChatBotScreen> createState() => _CustomerChatBotScreenState();
}

class _CustomerChatBotScreenState extends State<CustomerChatBotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// Dummy Q&A: keyword(s) in query (lowercase) -> response.
  static final Map<String, String> _dummyQna = {
    'what is doffer': 'D\'Offer is a hyperlocal deals app. Discover offers from shops near you, save favorites, and get the best deals in your area.',
    'what is this app': 'D\'Offer helps you discover amazing deals near you. Browse offers by location, like your favorites, and redeem them at the store.',
    'how do i redeem': 'To redeem an offer, open the offer details and show it to the shopkeeper at the store. They will verify and apply the discount for you.',
    'redeem offer': 'Show the offer to the shopkeeper when you visit the store. They\'ll confirm and give you the discount.',
    'save offer': 'Tap the heart icon on any offer to save it. Saved offers appear in the Favorites tab for easy access.',
    'favorites': 'Your liked offers are in the Favorites tab—tap the heart icon in the bottom navigation to view them.',
    'where are my favorites': 'Go to the Favorites tab (heart icon) in the bottom bar to see all offers you\'ve liked.',
    'how do i like': 'Tap the heart icon on an offer card to like it. Liked offers are saved in your Favorites tab.',
    'filter': 'Use the filter icon on the Offers tab to filter by state, city, or pincode. You can also use the search bar to find specific offers.',
    'search': 'On the Offers tab, use the search bar at the top to search by offer title or description. Use filters for location.',
    'help': 'I can help with: redeeming offers, saving favorites, searching and filtering. Try asking "How do I redeem an offer?" or "Where are my favorites?"',
    'hello': 'Hi! I\'m the D\'Offer assistant. Ask me about offers, favorites, or how to redeem deals.',
    'hi': 'Hello! How can I help you today? You can ask about redeeming offers, saving favorites, or using the app.',
  };

  static const List<String> _suggestedQuestions = [
    'What is D\'Offer?',
    'How do I redeem an offer?',
    'Where are my favorites?',
    'How do I save offers?',
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      'Hi! I\'m your D\'Offer assistant. Ask me anything about offers, favorites, or how to use the app.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToEnd();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getDummyResponse(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return 'Please type a question.';

    for (final entry in _dummyQna.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'I\'m not sure about that. Try asking: "How do I redeem an offer?" or "Where are my favorites?" You can also use the suggested questions below.';
  }

  void _onSend(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _controller.clear();
    _addUserMessage(trimmed);

    // Simulate short delay before bot reply
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _addBotMessage(_getDummyResponse(trimmed));
    });
  }

  void _onSuggestedTap(String question) {
    _onSend(question);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeHelper.isDarkMode(context);

    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.3),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Help'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _ChatBubble(
                    text: msg.text,
                    isUser: msg.isUser,
                    isDark: isDark,
                  );
                },
              ),
            ),
            if (_messages.length == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedQuestions.map((q) {
                    return ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 13)),
                      onPressed: () => _onSuggestedTap(q),
                      backgroundColor: isDark ? AppColors.surface : AppColors.lightSurface,
                    );
                  }).toList(),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface.withOpacity(0.5) : AppColors.lightSurface.withOpacity(0.9),
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask about offers, favorites...',
                          filled: true,
                          fillColor: isDark ? AppColors.cardBackground : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _onSend,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      child: InkWell(
                        onTap: () => _onSend(_controller.text),
                        borderRadius: BorderRadius.circular(24),
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark ? AppColors.surface : AppColors.lightSurface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
