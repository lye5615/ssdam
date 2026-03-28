import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _localNotifications => FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize Timezone
    tz.initializeTimeZones();

    // Initialize Local Notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Listen for background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<bool> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      print('⚠️ FCM 토큰 획득 실패: $e');
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    // [USER REQUEST] Remove screenshot-based auto-generated notifications.
    // Manual reminders are handled locally via zonedSchedule and don't come through FCM.
    // If FCM is only used for auto-generated sync alerts, we disable it in foreground.
    /*
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? '알림',
        message.notification!.body ?? '',
        message.data['payload'],
      );
    }
    */
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Notification caused app to open from background: ${message.data}');
  }

  Future<void> _showLocalNotification(String title, String body, String? payload) async {
    const androidDetails = AndroidNotificationDetails(
      'kimchi_jjim_notifications',
      '김치찜 알림',
      channelDescription: '스크린샷 관리 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const darwinDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'kimchi_jjim_reminders',
      '김치찜 리마인더',
      channelDescription: '개별 스크린샷 리마인더 알림',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const darwinDetails = DarwinNotificationDetails();
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Note: uiLocalNotificationDateInterpretation is removed in v19.5.0
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    
    print('⏰ 알림 예약 완료: $id, $scheduledDate');
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    print('🚫 알림 취소 완료: $id');
  }
}
