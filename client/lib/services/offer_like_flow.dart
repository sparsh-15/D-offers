import 'auth_service.dart';
import 'reward_service.dart';

class LikeToggleResult {
  const LikeToggleResult({
    required this.isLiked,
    required this.likesCount,
  });

  final bool isLiked;
  final int likesCount;
}

class LikeRewardOutcome {
  const LikeRewardOutcome({
    this.unlikeSplashAmount,
    this.message,
  });

  final int? unlikeSplashAmount;
  final String? message;
}

class OfferLikeFlow {
  OfferLikeFlow._();

  static final OfferLikeFlow instance = OfferLikeFlow._();
  static const int immediateLikeSplashAmount = 50;

  Future<LikeToggleResult> toggleLike(String offerId) async {
    final result = await AuthService.instance.toggleOfferLike(offerId);
    return LikeToggleResult(
      isLiked: result['isLiked'] as bool,
      likesCount: result['likesCount'] as int,
    );
  }

  Future<LikeRewardOutcome> settleReward({
    required String offerId,
    required bool isLikedNow,
  }) async {
    String? message;
    int? unlikeSplashAmount;

    try {
      if (isLikedNow) {
        try {
          await RewardService.instance.awardLikeReward(offerId);
        } catch (error) {
          message = _likeRewardFailureMessage(error);
        }
      } else {
        try {
          final reversal = await RewardService.instance.reverseLikeReward(offerId);
          final reversed = reversal['reversed'] == true;
          final reason = reversal['reason']?.toString();

          if (reversed) {
            unlikeSplashAmount = _extractLedgerAmount(reversal);
          } else {
            message = RewardService.instance.unlikeReversalReasonMessage(reason);
          }
        } catch (_) {
          // Keep unlike UX non-blocking even if reversal request fails.
        }
      }
    } finally {
      await RewardService.instance.refreshMyWalletBalance();
    }

    return LikeRewardOutcome(
      unlikeSplashAmount: unlikeSplashAmount,
      message: message,
    );
  }

  int? _extractLedgerAmount(Map<String, dynamic>? payload) {
    final ledger = payload?['ledgerEntry'];
    if (ledger is Map<String, dynamic>) {
      final amount = ledger['amount'];
      if (amount is num) return amount.toInt();
      final parsedInt = int.tryParse('$amount');
      if (parsedInt != null) return parsedInt;
      final parsedDouble = double.tryParse('$amount');
      if (parsedDouble != null) return parsedDouble.toInt();
    }
    return null;
  }

  String _likeRewardFailureMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final normalized = message.toLowerCase();
    if (normalized.contains('daily like reward limit')) {
      return 'Daily like reward limit reached.';
    }
    if (normalized.contains('daily coin earning cap exceeded')) {
      return 'Daily coin earning cap reached for today.';
    }
    if (normalized.contains('reward already granted')) {
      return 'Coins for this offer are already claimed.';
    }
    if (normalized.contains('re-like reward window expired') ||
        normalized.contains('relike_window_expired')) {
      return 'Re-like reward window expired for this offer.';
    }
    return 'Like saved, but coins were not added.';
  }
}
