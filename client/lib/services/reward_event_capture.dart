import 'reward_service.dart';
import 'auth_store.dart';

enum RewardEventType {
  saleClosed,
  installVerified,
}

class RewardEventCapture {
  RewardEventCapture._();

  static final RewardEventCapture instance = RewardEventCapture._();

  Future<void> capture(
    RewardEventType eventType, {
    required String sourceRef,
    String? deviceFingerprint,
  }) async {
    final ref = sourceRef.trim();
    if (ref.isEmpty) return;
    if (!RewardService.instance.isShopkeeper) return;

    switch (eventType) {
      case RewardEventType.saleClosed:
        await RewardService.instance.awardShopSaleReward(ref);
        break;
      case RewardEventType.installVerified:
        await RewardService.instance.awardInstallReward(
          installId: ref,
          deviceFingerprint: _normalizeDeviceFingerprint(
            deviceFingerprint,
            sourceRef: ref,
          ),
        );
        break;
    }
  }

  Future<void> captureSaleClosed(String saleRef) {
    return capture(RewardEventType.saleClosed, sourceRef: saleRef);
  }

  Future<void> captureInstallVerified(
    String installRef, {
    String? deviceFingerprint,
  }) {
    return capture(
      RewardEventType.installVerified,
      sourceRef: installRef,
      deviceFingerprint: deviceFingerprint,
    );
  }

  String _normalizeDeviceFingerprint(String? value,
      {required String sourceRef}) {
    final provided = value?.trim() ?? '';
    if (provided.isNotEmpty) return provided;
    final userId = AuthStore.currentUser?.id ?? 'unknown';
    return 'shop-install:$userId:$sourceRef';
  }
}
