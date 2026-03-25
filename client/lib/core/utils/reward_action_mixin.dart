import 'package:flutter/material.dart';

import '../../services/reward_event_capture.dart';

mixin RewardActionMixin<T extends StatefulWidget> on State<T> {
  void emitRewardEvent(
    RewardEventType eventType,
    String sourceRef, {
    String? deviceFingerprint,
  }) {
    RewardEventCapture.instance
        .capture(
      eventType,
      sourceRef: sourceRef,
      deviceFingerprint: deviceFingerprint,
    )
        .catchError((_) {
      // Reward events are intentionally fire-and-forget for UI actions.
    });
  }

  void emitSaleClosedReward(String saleRef) {
    emitRewardEvent(RewardEventType.saleClosed, saleRef);
  }

  void emitInstallVerifiedReward(
    String installRef, {
    String? deviceFingerprint,
  }) {
    emitRewardEvent(
      RewardEventType.installVerified,
      installRef,
      deviceFingerprint: deviceFingerprint,
    );
  }
}
