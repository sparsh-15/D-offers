import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_design_tokens.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/chat_assistant_service.dart';

/// AI chat assistant screen — premium dark design.
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
    "What is MyOffers?",
  ];

  static final Map<String, String> _localFallback = {
    'hello': "Hi! I'm your MyOffers assistant. What can I help you with today?",
    'hi': "Hello! Ask me about deals, favorites, or how to use the app.",
    'redeem': 'Show the offer to the shopkeeper at their store — they\'ll verify and apply the discount.',
    'favorites': 'Tap the heart icon on any offer to save it. Find saved offers in the Favorites tab.',
    'how': 'Try: "What deals are near me?" or "How do I redeem an offer?"',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text: "Hi! I'm your MyOffers assistant. Ask me about deals near you, how to redeem offers, or anything else.",
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
        context,
        'Assistant is temporarily unavailable.',
      );
    }
    _scrollToEnd();
  }

  void _handleAction(ChatAssistantAction action) {
    switch (action.type) {
      case 'ask_followup':
        {
          final msg = action.payload['message']?.toString() ?? action.label;
          _send(msg);
        }
        break;
      case 'open_offer':
      case 'open_offers_tab':
      case 'open_coupons_tab':
      case 'open_favorites':
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accentDim.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: AppTokens.spaceSM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Assistant',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'MyOffers',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages ────────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceMD, AppTokens.spaceSM,
                AppTokens.spaceMD, AppTokens.spaceMD,
              ),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_isSending && i == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Bubble(
                      text: msg.text,
                      isUser: msg.isUser,
                    ),
                    if (!msg.isUser && msg.actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppTokens.spaceXS,
                          bottom: AppTokens.spaceSM,
                        ),
                        child: Wrap(
                          spacing: AppTokens.spaceSM,
                          runSpacing: AppTokens.spaceXS,
                          children: msg.actions
                              .map(
                                (a) => GestureDetector(
                                  onTap: () => _handleAction(a),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTokens.spaceMD,
                                      vertical: AppTokens.spaceXS + 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevated,
                                      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                                      border: Border.all(
                                        color: AppColors.borderMid,
                                      ),
                                    ),
                                    child: Text(
                                      a.label,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ── Suggested questions (expandable) ────────────────────────────────
          _SuggestedSection(
            expanded: _askExpanded,
            questions: _suggestedQuestions,
            onToggle: () => setState(() => _askExpanded = !_askExpanded),
            onTap: (q) => _send(q),
          ),

          // ── Input bar ───────────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
              AppTokens.spaceMD,
              AppTokens.spaceSM,
              AppTokens.spaceSM,
              MediaQuery.of(context).padding.bottom + AppTokens.spaceSM,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: AppColors.elevated,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMD),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask anything…',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                          vertical: AppTokens.spaceSM + 2,
                        ),
                        filled: false,
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceSM),
                GestureDetector(
                  onTap: _isSending
                      ? null
                      : () => _send(_inputController.text),
                  child: AnimatedContainer(
                    duration: AppTokens.durationFast,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? AppColors.accentDim.withValues(alpha: 0.4)
                          : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _isSending ? AppColors.textMuted : AppColors.black,
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

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

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMD,
          vertical: AppTokens.spaceSM + 2,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.accentDim : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTokens.radiusMD),
            topRight: const Radius.circular(AppTokens.radiusMD),
            bottomLeft: Radius.circular(isUser ? AppTokens.radiusMD : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppTokens.radiusMD),
          ),
        ),
        child: Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? AppColors.white : AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.spaceSM),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMD,
          vertical: AppTokens.spaceSM + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTokens.radiusMD),
            topRight: Radius.circular(AppTokens.radiusMD),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(AppTokens.radiusMD),
          ),
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
    _anim = Tween(begin: 0.4, end: 1.0).animate(
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
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

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
    final theme = Theme.of(context);
    return Column(
      children: [
        const Divider(color: AppColors.borderSubtle, height: 1),
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMD,
              vertical: AppTokens.spaceXS + 2,
            ),
            child: Row(
              children: [
                Text(
                  'Ask me about…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: AppColors.textMuted,
                  size: AppTokens.iconMD,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceMD, 0, AppTokens.spaceMD, AppTokens.spaceSM,
            ),
            child: Wrap(
              spacing: AppTokens.spaceSM,
              runSpacing: AppTokens.spaceXS,
              children: questions
                  .map(
                    (q) => GestureDetector(
                      onTap: () => onTap(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spaceMD,
                          vertical: AppTokens.spaceXS + 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          q,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
