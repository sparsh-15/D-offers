import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/campaign_model.dart';
import '../../services/campaign_service.dart';
import '../../widgets/data_state_wrapper.dart';

class CustomerInboxScreen extends StatefulWidget {
  const CustomerInboxScreen({super.key});

  @override
  State<CustomerInboxScreen> createState() => _CustomerInboxScreenState();
}

class _CustomerInboxScreenState extends State<CustomerInboxScreen> {
  bool _loading = true;
  String? _error;
  List<InboxMessageModel> _messages = const [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await CampaignService.instance.getInboxMessages();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openMessage(InboxMessageModel message) async {
    if (!message.isRead) {
      try {
        await CampaignService.instance.markInboxMessageRead(message.id);
        if (!mounted) return;
        setState(() {
          _messages = _messages.map((item) {
            if (item.id != message.id) return item;
            return InboxMessageModel(
              id: item.id,
              campaignId: item.campaignId,
              shopkeeperId: item.shopkeeperId,
              offerId: item.offerId,
              title: item.title,
              body: item.body,
              bannerUrl: item.bannerUrl,
              isRead: true,
              readAt: DateTime.now(),
              createdAt: item.createdAt,
              shopkeeperName: item.shopkeeperName,
              campaignStatus: item.campaignStatus,
            );
          }).toList();
        });
      } catch (_) {}
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'From ${message.shopkeeperName}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (message.bannerUrl != null && message.bannerUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      message.bannerUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(message.body),
                const SizedBox(height: 16),
                if ((message.offerId ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This message is linked to an offer. Browse the offers tab to view it.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: DataStateWrapper(
        loading: _loading,
        error: _error,
        isEmpty: _messages.isEmpty,
        onRetry: _loadMessages,
        emptyTitle: 'No campaign messages yet',
        emptyMessage: 'When shops launch campaigns for your area, they will show up here.',
        child: RefreshIndicator(
          onRefresh: _loadMessages,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _openMessage(message),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: message.isRead
                            ? AppColors.surface
                            : AppColors.accent.withValues(alpha: 0.18),
                        child: const Icon(Icons.notifications_active_rounded),
                      ),
                      if (!message.isRead)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(message.title),
                  subtitle: Text(
                    '${message.shopkeeperName}\n${message.body}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
