class CampaignAnalytics {
  final int totalReached;
  final int opened;
  final int clicked;
  final int failed;
  final double openRate;
  final double clickRate;
  final Map<String, dynamic> channelBreakdown;

  const CampaignAnalytics({
    required this.totalReached,
    required this.opened,
    required this.clicked,
    required this.failed,
    required this.openRate,
    required this.clickRate,
    required this.channelBreakdown,
  });

  factory CampaignAnalytics.fromJson(Map<String, dynamic> json) {
    return CampaignAnalytics(
      totalReached: int.tryParse(json['totalReached']?.toString() ?? '0') ?? 0,
      opened: int.tryParse(json['opened']?.toString() ?? '0') ?? 0,
      clicked: int.tryParse(json['clicked']?.toString() ?? '0') ?? 0,
      failed: int.tryParse(json['failed']?.toString() ?? '0') ?? 0,
      openRate: double.tryParse(json['openRate']?.toString() ?? '0') ?? 0,
      clickRate: double.tryParse(json['clickRate']?.toString() ?? '0') ?? 0,
      channelBreakdown: Map<String, dynamic>.from(
        json['channelBreakdown'] as Map? ?? const {},
      ),
    );
  }
}

class CampaignTemplateModel {
  final String id;
  final String name;
  final String category;
  final String bannerUrl;
  final String? description;

  const CampaignTemplateModel({
    required this.id,
    required this.name,
    required this.category,
    required this.bannerUrl,
    this.description,
  });

  factory CampaignTemplateModel.fromJson(Map<String, dynamic> json) {
    return CampaignTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'all',
      bannerUrl: json['bannerUrl']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

class InboxMessageModel {
  final String id;
  final String? campaignId;
  final String? shopkeeperId;
  final String? offerId;
  final String title;
  final String body;
  final String? bannerUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String shopkeeperName;
  final String? campaignStatus;

  const InboxMessageModel({
    required this.id,
    this.campaignId,
    this.shopkeeperId,
    this.offerId,
    required this.title,
    required this.body,
    this.bannerUrl,
    required this.isRead,
    this.readAt,
    this.createdAt,
    required this.shopkeeperName,
    this.campaignStatus,
  });

  factory InboxMessageModel.fromJson(Map<String, dynamic> json) {
    return InboxMessageModel(
      id: json['id']?.toString() ?? '',
      campaignId: json['campaignId']?.toString(),
      shopkeeperId: json['shopkeeperId']?.toString(),
      offerId: json['offerId']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      bannerUrl: json['bannerUrl']?.toString(),
      isRead: json['isRead'] == true,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      shopkeeperName: json['shopkeeperName']?.toString() ?? 'Nearby shop',
      campaignStatus: json['campaignStatus']?.toString(),
    );
  }
}

class CampaignModel {
  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final String bannerType;
  final String shopCategory;
  final List<String> channels;
  final String status;
  final String? targetCity;
  final String? targetArea;
  final String? targetPincode;
  final String? targetState;
  final int? targetAgeMin;
  final int? targetAgeMax;
  final String? targetGender;
  final int estimatedAudience;
  final int selectedAudienceSize;
  final int actualAudienceReached;
  final double whatsappUnitPrice;
  final double inboxUnitPrice;
  final double totalCost;
  final String paymentStatus;
  final String? paymentMethod;
  final String? transactionId;
  final String? offerId;
  final Map<String, dynamic>? offer;
  final DateTime? scheduledAt;
  final DateTime? launchedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CampaignAnalytics? analytics;

  const CampaignModel({
    required this.id,
    required this.title,
    this.description,
    this.bannerUrl,
    required this.bannerType,
    required this.shopCategory,
    required this.channels,
    required this.status,
    this.targetCity,
    this.targetArea,
    this.targetPincode,
    this.targetState,
    this.targetAgeMin,
    this.targetAgeMax,
    this.targetGender,
    required this.estimatedAudience,
    required this.selectedAudienceSize,
    required this.actualAudienceReached,
    required this.whatsappUnitPrice,
    required this.inboxUnitPrice,
    required this.totalCost,
    required this.paymentStatus,
    this.paymentMethod,
    this.transactionId,
    this.offerId,
    this.offer,
    this.scheduledAt,
    this.launchedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.analytics,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      bannerType: json['bannerType']?.toString() ?? 'template',
      shopCategory: json['shopCategory']?.toString() ?? 'general',
      channels: (json['channels'] as List? ?? const [])
          .map((channel) => channel.toString())
          .toList(),
      status: json['status']?.toString() ?? 'draft',
      targetCity: json['targetCity']?.toString(),
      targetArea: json['targetArea']?.toString(),
      targetPincode: json['targetPincode']?.toString(),
      targetState: json['targetState']?.toString(),
      targetAgeMin: int.tryParse(json['targetAgeMin']?.toString() ?? ''),
      targetAgeMax: int.tryParse(json['targetAgeMax']?.toString() ?? ''),
      targetGender: json['targetGender']?.toString(),
      estimatedAudience:
          int.tryParse(json['estimatedAudience']?.toString() ?? '0') ?? 0,
      selectedAudienceSize:
          int.tryParse(json['selectedAudienceSize']?.toString() ?? '0') ?? 0,
      actualAudienceReached:
          int.tryParse(json['actualAudienceReached']?.toString() ?? '0') ?? 0,
      whatsappUnitPrice:
          double.tryParse(json['whatsappUnitPrice']?.toString() ?? '0') ?? 0,
      inboxUnitPrice:
          double.tryParse(json['inboxUnitPrice']?.toString() ?? '0') ?? 0,
      totalCost: double.tryParse(json['totalCost']?.toString() ?? '0') ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      offerId: json['offerId']?.toString(),
      offer: json['offer'] is Map<String, dynamic>
          ? json['offer'] as Map<String, dynamic>
          : json['offer'] is Map
              ? Map<String, dynamic>.from(json['offer'] as Map)
              : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      launchedAt: json['launchedAt'] != null
          ? DateTime.tryParse(json['launchedAt'].toString())
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      analytics: json['analytics'] is Map<String, dynamic>
          ? CampaignAnalytics.fromJson(json['analytics'] as Map<String, dynamic>)
          : json['analytics'] is Map
              ? CampaignAnalytics.fromJson(
                  Map<String, dynamic>.from(json['analytics'] as Map),
                )
              : null,
    );
  }
}

class AudienceEstimate {
  final int audienceCount;
  final int selectedAudienceSize;
  final double inboxUnitPrice;
  final double whatsappUnitPrice;
  final double totalCost;

  const AudienceEstimate({
    required this.audienceCount,
    required this.selectedAudienceSize,
    required this.inboxUnitPrice,
    required this.whatsappUnitPrice,
    required this.totalCost,
  });

  factory AudienceEstimate.fromJson(Map<String, dynamic> json) {
    final cost = Map<String, dynamic>.from(json['cost'] as Map? ?? const {});
    final pricing = Map<String, dynamic>.from(
      json['pricing'] as Map? ?? const {},
    );
    return AudienceEstimate(
      audienceCount: int.tryParse(json['audienceCount']?.toString() ?? '0') ?? 0,
      selectedAudienceSize:
          int.tryParse(json['selectedAudienceSize']?.toString() ?? '0') ?? 0,
      inboxUnitPrice:
          double.tryParse(pricing['appInbox']?.toString() ?? '0') ?? 0,
      whatsappUnitPrice:
          double.tryParse(pricing['whatsapp']?.toString() ?? '0') ?? 0,
      totalCost: double.tryParse(cost['totalCost']?.toString() ?? '0') ?? 0,
    );
  }
}