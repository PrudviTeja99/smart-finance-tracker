import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/app_settings.dart';

class PrivacyController {
  bool obscureAmounts = false;
  bool isAutoHideTimerActive = false;
  int remainingSeconds = 0;
  Timer? autoHideTimer;
  Timer? countdownTimer;

  final VoidCallback onStateChanged;

  PrivacyController({required this.onStateChanged});

  Future<void> loadSavedPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    obscureAmounts = prefs.getBool('obscure_amounts') ?? false;
    onStateChanged();
  }

  Future<void> setObscureAmounts(bool value) async {
    obscureAmounts = value;
    onStateChanged();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('obscure_amounts', obscureAmounts);
  }

  void startAutoHideTimerIfNeeded() {
    final enabled = AppSettings.autoHideEnabled;
    final timeoutSeconds = AppSettings.autoHideSeconds;

    if (enabled && obscureAmounts) {
      cancelAutoHideTimer();
      obscureAmounts = false;
      isAutoHideTimerActive = true;
      remainingSeconds = timeoutSeconds;
      onStateChanged();

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds > 1) {
          remainingSeconds--;
          onStateChanged();
        } else {
          timer.cancel();
        }
      });

      autoHideTimer = Timer(Duration(seconds: timeoutSeconds), () async {
        cancelAutoHideTimer();
        obscureAmounts = true;
        onStateChanged();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('obscure_amounts', true);
      });
    }
  }

  void cancelAutoHideTimer() {
    autoHideTimer?.cancel();
    countdownTimer?.cancel();
    autoHideTimer = null;
    countdownTimer = null;
    isAutoHideTimerActive = false;
    remainingSeconds = 0;
    onStateChanged();
  }

  void dispose() {
    autoHideTimer?.cancel();
    countdownTimer?.cancel();
  }
}
