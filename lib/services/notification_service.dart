import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/backend_config.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);
    } catch (e) {
      debugPrint('LOCAL_NOTIF_INIT_ERROR: $e');
    }
  }

  Future<void> updateToken(String userId, {String? token}) async {
    if (token == null || token.isEmpty) return;
    try {
      await Supabase.instance.client.from('users').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      await http.put(
        Uri.parse('${BackendConfig.baseUrl}/auth/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fcmToken': token}),
      );
    } catch (e) {
      debugPrint('updateToken error: $e');
    }
  }

  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'skillxchange_main',
      'Swap Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }
}

final notificationServiceProvider = Provider((ref) => NotificationService());
