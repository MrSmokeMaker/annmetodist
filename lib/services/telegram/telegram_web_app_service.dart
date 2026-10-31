import 'package:flutter/material.dart';
import 'telegram_models.dart';
import 'telegram_web_app_stub.dart'
    if (dart.library.html) 'telegram_web_app_web.dart';

export 'telegram_models.dart';

class TelegramWebAppService {
  static final TelegramWebAppService _instance = TelegramWebAppService._internal();
  factory TelegramWebAppService() => _instance;
  TelegramWebAppService._internal();

  final _platform = TelegramWebAppPlatform.instance;

  /// Открыто ли приложение внутри Telegram Mini App
  bool get isInsideTelegram => _platform.isTelegramWebApp;

  /// Авторизованный пользователь Telegram (если доступен)
  TelegramUser? get user => _platform.user;

  /// Параметр старта из ссылки вида t.me/annmetodist_bot?startapp=param
  String? get startParam => _platform.startParam;

  /// Системные цвета Telegram (светлая/тёмная тема)
  TelegramThemeParams get themeParams => _platform.themeParams;

  void init() {
    _platform.ready();
    _platform.expand();
  }

  void expand() => _platform.expand();
  void close() => _platform.close();

  void showBackButton(VoidCallback onClick) => _platform.showBackButton(onClick);
  void hideBackButton() => _platform.hideBackButton();

  void showMainButton(String text, VoidCallback onClick) => _platform.showMainButton(text, onClick);
  void hideMainButton() => _platform.hideMainButton();

  /// Тактильный отклик (Haptic Feedback)
  void hapticImpact([String style = 'medium']) => _platform.hapticImpact(style);
  void hapticNotification([String type = 'success']) => _platform.hapticNotification(type);
  void hapticSelection() => _platform.hapticSelection();

  void sendData(String data) => _platform.sendData(data);
}
