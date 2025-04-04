import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Initialize the notification plugin
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings(
      '@drawable/scsmall');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  AndroidFlutterLocalNotificationsPlugin().requestExactAlarmsPermission();
}

void showNotification(String? header, String? body) async {
  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'sc_channel_id',
    'Screen Sheriff',
    channelDescription: 'Notifications from Screen Sheriff',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    styleInformation: BigTextStyleInformation(''),
  );
  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails);

  // Using DateTime to generate a unique ID for each notification
  final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await flutterLocalNotificationsPlugin.show(
      notificationId, header, body, notificationDetails);
}