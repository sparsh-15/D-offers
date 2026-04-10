import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_design_tokens.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/auth_service.dart';
import '../../services/chat_assistant_service.dart';
import '../common/offer_detail_screen.dart';
import 'customer_dashboard.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
class _CP {
  static const canvas        = Color(0xFFF3F5F8);
  static const surface       = Color(0xFFFFFFFF);
  static const elevated      = Color(0xFFF4F7FB);
  static const border        = Color(0xFFDCE3EC);
  static const accent        = Color(0xFFE88428);
  static const accentSoft    = Color(0xFFFBE7D6);
  static const userBubble    = Color(0xFFE88428);
  static const botBubble     = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1E2433);
  static const textSecondary = Color(0xFF334155);
  static const textMuted     = Color(0xFF667085);
  static const white         = Color(0xFFFFFFFF);
}

class CustomerChatBotScreen extends StatefulWidget {
  const CustomerChatBotScreen({super.key});

  @override
  State<CustomerChatBotScreen> createState() => _CustomerChatBotScreenState();
}

class _CustomerChatBotScreenState extends State<CustomerChatBotScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _askExpanded = false;

  static const List<String> _suggestedQuestions = [
    "What deals are near me?",
    "How do I redeem an offer?",
    "Where are my saved offers?",
    'What is ${AppStrings.appName}?',
  ];

  static final Map<String, String> _localFallback = {
    'hello':
        "Hi! I'm your ${AppStrings.appName} assistant. What can I help you with today?",
    'hi': "Hello! Ask me about deals, favorites, or how to use the app.",
    'redeem':
        'Show the offer to the shopkeeper at their store — they\'ll verify and apply the discount.',
    'favorites':
        'Tap the heart icon on any offer to save it. Find saved offers in the Favorites tab.',
    'how': 'Try: "What deals are near me?" or "How do I redeem an offer?"',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            "Hi! I'm your ${AppStrings.appName} assistant. Ask me about deals near you, how to redeem offers, or anything else.",
        isUser: false,
        actions: const [],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppTokens.durationNormal,
          curve: AppTokens.curveDefault,
        );
      }
    });
  }

  String _localResponse(String query) {
    final lower = query.toLowerCase();
    for (final entry in _localFallback.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return "I'm not sure about that. Try asking about deals near you or how to redeem an offer.";
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true, actions: const []));
      _isSending = true;
    });
    _scrollToEnd();

    try {
      final result = await ChatAssistantService.instance.sendMessage(trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: result.reply,
          isUser: false,
          actions: result.actions,
        ));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: _localResponse(trimmed),
          isUser: false,
          actions: const [],
        ));
        _isSending = false;
      });
      DialogHelper.showErrorSnackBar(
          context, 'Assistant is temporarily unavailable.');
    }
    _scrollToEnd();
  }

  void _handleAction(ChatAssistantAction action) {
    switch (action.type) {
      case 'ask_followup':
        final msg = action.payload['message']?.toString() ?? action.label;
        _send(msg);
        break;
      case 'open_offer':
        final offerId = action.payload['offerId']?.toString();
        _openOfferDetail(offerId);
        break;
      case 'open_offers_tab':
      case 'open_favorites':
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 'open_coupons_tab':
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CustomerDashboard(initialTabIndex: 2),
          ),
          (route) => route.isFirst,
        );
        break;
      default:
        break;
    }
  }

  Future<void> _openOfferDetail(String? offerId) async {
    final id = offerId?.trim();
    if (id == null || id.isEmpty) {
      DialogHelper.showErrorSnackBar(context, 'Offer id is missing.');
      return;
    }
    try {
      final offer = await AuthService.instance.getCustomerOffer(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer)),
      );
    } catch (_) {
      if (!mounted) return;
      DialogHelper.showErrorSnackBar(
          context, 'Unable to open this offer right now.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CP.canvas,
      appBar: AppBar(
        backgroundColor: _CP.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: _CP.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF334155)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _CP.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: _CP.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _CP.textPrimary,
                  ),
                ),
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _CP.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _CP.border),
        ),
      ),
      body: Column(
        children: [
          // ── Messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_isSending && i == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Bubble(text: msg.text, isUser: msg.isUser),
                    if (!msg.isUser && msg.actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: msg.actions
                              .map((a) => GestureDetector(
                                    onTap: () => _handleAction(a),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: _CP.accentSoft,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _CP.accent
                                              .withValues(alpha: 0.35),
                                        ),
                                      ),
                                      child: Text(
                                        a.label,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: _CP.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Suggested questions ────────────────────────────────────────
          _SuggestedSection(
            expanded: _askExpanded,
            questions: _suggestedQuestions,
            onToggle: () => setState(() => _askExpanded = !_askExpanded),
            onTap: (q) => _send(q),
          ),

          // ── Input bar ──────────────────────────────────────────────────
          Container(
            color: _CP.surface,
            padding: EdgeInsets.fromLTRB(
              14,
              10,
              10,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: _CP.elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _CP.border),
                    ),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: _CP.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask anything…',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: _CP.textMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        filled: false,
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : () => _send(_inputController.text),
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? _CP.border
                          : _CP.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _isSending ? _CP.textMuted : _CP.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<ChatAssistantAction> actions;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.actions,
  });
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? _CP.userBubble : _CP.botBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: _CP.border),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: _CP.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: isUser ? _CP.white : _CP.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _CP.botBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: _CP.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedDot(delay: Duration.zero),
            const SizedBox(width: 4),
            _AnimatedDot(delay: const Duration(milliseconds: 160)),
            const SizedBox(width: 4),
            _AnimatedDot(delay: const Duration(milliseconds: 320)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: _CP.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Suggested questions section ───────────────────────────────────────────────

class _SuggestedSection extends StatelessWidget {
  final bool expanded;
  final List<String> questions;
  final VoidCallback onToggle;
  final ValueChanged<String> onTap;

  const _SuggestedSection({
    required this.expanded,
    required this.questions,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, color: _CP.border),
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: _CP.accent),
                const SizedBox(width: 6),
                Text(
                  'Ask me about…',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: _CP.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: _CP.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: questions
                  .map((q) => GestureDetector(
                        onTap: () => onTap(q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _CP.elevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _CP.border),
                          ),
                          child: Text(
                            q,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: _CP.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
