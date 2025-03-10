import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waterfinder/models/water_source.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> showWaterSourceNotification(WaterSource source) async {
    const androidDetails = AndroidNotificationDetails(
      'water_sources',
      'Water Sources',
      channelDescription: 'Notifications about nearby water sources',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      source.hashCode,
      'مصدر مياه قريب',
      'يوجد ${source.name} على بعد ${source.distance?.toStringAsFixed(1)} كم',
      details,
    );
  }

  Future<void> showContaminationAlert(WaterSource source) async {
    const androidDetails = AndroidNotificationDetails(
      'contamination_alerts',
      'Contamination Alerts',
      channelDescription: 'Alerts about contaminated water sources',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.red,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      source.hashCode,
      'تحذير: مصدر مياه ملوث',
      'تم الإبلاغ عن تلوث في ${source.name}',
      details,
    );
  }

  Future<void> checkNearbyWaterSources(
    Position userLocation,
    List<WaterSource> sources,
    double radius,
  ) async {
    for (final source in sources) {
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        source.location.latitude,
        source.location.longitude,
      );

      if (distance <= radius * 1000) { // Convert km to meters
        await showWaterSourceNotification(source);
      }
    }
  }

  Future<void> requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}