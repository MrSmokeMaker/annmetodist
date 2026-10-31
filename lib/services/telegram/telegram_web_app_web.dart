// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'telegram_models.dart';

class TelegramWebAppPlatform {
  static final TelegramWebAppPlatform instance = TelegramWebAppPlatform();

  dynamic get _tg => js.context['Telegram'];
  dynamic get _wa => _tg != null ? _tg['WebApp'] : null;

  bool get isTelegramWebApp {
    try {
      if (_wa == null) return false;
      final initData = _wa['initData'] as String?;
      return initData != null && initData.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  TelegramUser? get user {
    try {
      if (_wa == null) return null;
      final unsafe = _wa['initDataUnsafe'];
      if (unsafe == null) return null;
      final u = unsafe['user'];
      if (u == null) return null;

      final jsonStr = js.context['JSON'].callMethod('stringify', [u]) as String;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TelegramUser.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  String? get startParam {
    try {
      if (_wa == null) return null;
      final unsafe = _wa['initDataUnsafe'];
      if (unsafe == null) return null;
      return unsafe['start_param'] as String?;
    } catch (_) {
      return null;
    }
  }

  TelegramThemeParams get themeParams {
    try {
      if (_wa == null) return const TelegramThemeParams();
      final tp = _wa['themeParams'];
      if (tp == null) return const TelegramThemeParams();

      final jsonStr = js.context['JSON'].callMethod('stringify', [tp]) as String;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TelegramThemeParams.fromMap(map);
    } catch (_) {
      return const TelegramThemeParams();
    }
  }

  void ready() {
    try {
      _wa?.callMethod('ready');
    } catch (_) {}
  }

  void expand() {
    try {
      _wa?.callMethod('expand');
    } catch (_) {}
  }

  void close() {
    try {
      _wa?.callMethod('close');
    } catch (_) {}
  }

  void showBackButton(VoidCallback onClick) {
    try {
      final bb = _wa?['BackButton'];
      if (bb != null) {
        bb.callMethod('show');
        bb.callMethod('onClick', [js.allowInterop((_) => onClick())]);
      }
    } catch (_) {}
  }

  void hideBackButton() {
    try {
      _wa?['BackButton']?.callMethod('hide');
    } catch (_) {}
  }

  void showMainButton(String text, VoidCallback onClick) {
    try {
      final mb = _wa?['MainButton'];
      if (mb != null) {
        mb.callMethod('setText', [text]);
        mb.callMethod('show');
        mb.callMethod('onClick', [js.allowInterop((_) => onClick())]);
      }
    } catch (_) {}
  }

  void hideMainButton() {
    try {
      _wa?['MainButton']?.callMethod('hide');
    } catch (_) {}
  }

  void hapticImpact([String style = 'medium']) {
    try {
      _wa?['HapticFeedback']?.callMethod('impactOccurred', [style]);
    } catch (_) {}
  }

  void hapticNotification([String type = 'success']) {
    try {
      _wa?['HapticFeedback']?.callMethod('notificationOccurred', [type]);
    } catch (_) {}
  }

  void hapticSelection() {
    try {
      _wa?['HapticFeedback']?.callMethod('selectionChanged');
    } catch (_) {}
  }

  void sendData(String data) {
    try {
      _wa?.callMethod('sendData', [data]);
    } catch (_) {}
  }
}
