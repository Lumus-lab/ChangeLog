import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // --- Rewarded Ad IDs ---
  static String get rewardedAdUnitId {
    if (kReleaseMode) {
      // TODO: Replace with your actual production Ad Unit ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
  }

  // --- Interstitial Ad IDs ---
  static String get interstitialAdUnitId {
    if (kReleaseMode) {
      // TODO: Replace with your actual production Ad Unit ID
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    } else {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
  }

  // --- Methods ---

  /// 加載並顯示獎勵廣告
  static void showRewardedAd({
    required Function(RewardItem reward) onRewardEarned,
    Function()? onAdFailed,
  }) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onAdFailed != null) onAdFailed();
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              onRewardEarned(reward);
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (onAdFailed != null) onAdFailed();
        },
      ),
    );
  }

  /// 加載並顯示插頁廣告
  static void showInterstitialAd({Function()? onAdClosed}) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (onAdClosed != null) onAdClosed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (onAdClosed != null) onAdClosed();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (onAdClosed != null) onAdClosed();
        },
      ),
    );
  }
}
