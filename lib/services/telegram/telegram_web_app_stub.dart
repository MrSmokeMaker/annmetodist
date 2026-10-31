import 'package:flutter/material.dart';
import 'telegram_models.dart';

class TelegramWebAppPlatform {
  static final TelegramWebAppPlatform instance = TelegramWebAppPlatform();

  bool get isTelegramWebApp => false;
  TelegramUser? get user => null;
  String? get startParam => null;
  TelegramThemeParams get themeParams => const TelegramThemeParams();

  void ready() {}
  void expand() {}
  void close() {}

  void showBackButton(VoidCallback onClick) {}
  void hideBackButton() {}

  void showMainButton(String text, VoidCallback onClick) {}
  void hideMainButton() {}

  void hapticImpact([String style = 'medium']) {}
  void hapticNotification([String type = 'success']) {}
  void hapticSelection() {}

  void sendData(String data) {}
  void openTelegramLink(String url) {}
  void openLink(String url) {}
}
