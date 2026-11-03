import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';

class AppNotificationService extends ChangeNotifier {
  static const String _storageKey = 'metodist_app_notifications_v1';
  static const int _maxStoredNotifications = 50;

  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _incomingController =
      StreamController<AppNotification>.broadcast();

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<AppNotification> get onIncomingNotification => _incomingController.stream;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_storageKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
        _notifications.clear();
        for (final item in decoded) {
          try {
            _notifications.add(AppNotification.fromMap(item as Map<String, dynamic>));
          } catch (_) {}
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AppNotificationService init error: $e');
    }
  }

  Future<void> notify({
    required String title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
    Map<String, dynamic>? payload,
  }) async {
    final notification = AppNotification(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_notifications.length}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      payload: payload,
    );

    _notifications.insert(0, notification);
    if (_notifications.length > _maxStoredNotifications) {
      _notifications.removeLast();
    }

    _incomingController.add(notification);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listData = _notifications.map((n) => n.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(listData));
    } catch (e) {
      debugPrint('AppNotificationService save error: $e');
    }
  }

  @override
  void dispose() {
    _incomingController.close();
    super.dispose();
  }
}
