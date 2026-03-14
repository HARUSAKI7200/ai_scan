// lib/utils/ad_manager.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<bool> showRewardedAd(BuildContext context) async {
    bool isEarnedReward = false;
    String? loadErrorMessage;
    
    // ★追加: 広告のロード完了を待機するためのCompleter
    final loadCompleter = Completer<RewardedAd?>();
    // ★追加: 動画の視聴完了（閉じる）を待機するためのCompleter
    final showCompleter = Completer<bool>();

    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('広告を準備中...'),
              ],
            ),
          ),
        ),
      ),
    );

    // 広告の読み込みを開始
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // 読み込み成功時、Completerに広告データを渡して待機を解除
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(ad);
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('広告の読み込みに失敗しました: $error');
          loadErrorMessage = error.message;
          // 読み込み失敗時、nullを渡して待機を解除
          if (!loadCompleter.isCompleted) {
            loadCompleter.complete(null);
          }
        },
      ),
    );

    // ★重要: ここでロード完了のコールバックが呼ばれるまで処理を完全にストップさせる
    RewardedAd? rewardedAd = await loadCompleter.future;

    // ダイアログを閉じる
    if (context.mounted) {
      Navigator.pop(context);
    }

    // 広告の取得に失敗した場合
    if (rewardedAd == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('広告の準備に失敗しました\n理由: ${loadErrorMessage ?? "不明なエラー"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false; 
    }

    // 表示時のイベントコールバック設定
    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(isEarnedReward);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!showCompleter.isCompleted) {
          showCompleter.complete(false);
        }
      },
    );

    // 広告を表示する
    await rewardedAd.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        isEarnedReward = true; // ユーザーが最後まで視聴したフラグを立てる
      }
    );

    // 広告が閉じられるまで待機して、結果を返す
    return showCompleter.future;
  }
}