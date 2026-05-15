// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const macOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      macOS: macOSSettings, // Use the macOS-specific settings
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap or action
        print('Notification clicked: ${response.payload}');
      },
    );
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const macOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(macOS: macOSDetails);
    await _notifications.show(
      id: id, // Use named parameters
      title: title,
      body: body,
      notificationDetails: details, // Use the correct named parameter
    );
  }
}