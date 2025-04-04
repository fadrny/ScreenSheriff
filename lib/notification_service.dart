import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'utils.dart';
import 'ai_helper.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';
import 'main.dart'; // Import main.dart to access Temperature and Language
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Initialize the notification plugin
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@drawable/scsmall');
  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
  );

  tz.initializeTimeZones();
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await AndroidFlutterLocalNotificationsPlugin().requestExactAlarmsPermission();
}

Future<void> scheduleNotification(
    TimeOfDay notificationTime, Temperature temperature, Language language) async {
  final now = DateTime.now();
  DateTime scheduledDate = DateTime(
      now.year, now.month, now.day, notificationTime.hour, notificationTime.minute);
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

  // Schedule the notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Screen Sheriff',
    'Time to check your screen time!', // Initial message
    tzScheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'scheduled_channel_id',
        'Scheduled Notifications',
        channelDescription: 'Channel for scheduled notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: '${temperature.index},${language.index}',
  );
}

Future<void> generateAndShowNotification(
    Temperature temperature, Language language) async {
  List<AppUsageInfo> usageInfo = await getUsageStats();

  if (usageInfo.isNotEmpty) {
    int totalMinutes = getTopTenApps(usageInfo)
        .fold(0, (sum, info) => sum + info.usage.inMinutes);
    double totalHours = totalMinutes / 60;
    List<String> appNames = getTopTenApps(usageInfo)
        .map((info) => '${info.packageName}: ${info.usage.inMinutes.toString()} min')
        .toList();

    AiHelper aiHelper = AiHelper();
    Map<String, dynamic> notification = await aiHelper.generateNotification(
        totalHours.round(),
        appNames,
        temperature == Temperature.goodCop,
        language == Language.czech);

    showNotification(notification['header'], notification['body']);
  }
}

List<AppUsageInfo> getTopTenApps(List<AppUsageInfo> infos) {
  infos.sort((a, b) => b.usage.compareTo(a.usage));
  return infos.take(10).toList();
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

  final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await flutterLocalNotificationsPlugin.show(
      notificationId, header, body, notificationDetails);
}

Future<void> configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = tz.local.toString();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}