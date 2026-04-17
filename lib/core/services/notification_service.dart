import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    debugPrint('[NotificationService] Initializing...');
    
    // Android initialization settings
    // FIXED: Removed '@mipmap/' prefix. The plugin expects the name of the drawable.
    // Ensure you have an icon named 'launcher_icon' or 'ic_launcher' in your drawable/mipmap folders.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      final bool? initialized = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[NotificationService] Notification clicked: ${response.payload}');
        },
      );
      debugPrint('[NotificationService] Plugin initialization status: $initialized');
    } catch (e) {
      debugPrint('[NotificationService] ERROR during initialization: $e');
    }

    // Create Android Notification Channel for high importance
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      debugPrint('[NotificationService] Android High Importance Channel ensured');
    } catch (e) {
      debugPrint('[NotificationService] ERROR creating channel: $e');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('[NotificationService] Preparing to show notification: "$title"');
    
    // Check if initialization happened or needs re-check
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.message,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a unique ID if possible or keep the provided one
    final notificationId = id == 1 || id == 2 
        ? DateTime.now().millisecondsSinceEpoch % 100000 
        : id;

    try {
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: payload,
      );
      debugPrint('[NotificationService] Notification displayed successfully with ID: $notificationId');
    } catch (e) {
      debugPrint('[NotificationService] ERROR showing notification: $e');
      // If fails, try to re-request permission
      await requestPermissions();
    }
  }

  Future<void> requestPermissions() async {
    debugPrint('[NotificationService] Requesting permissions...');
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? granted = await androidImplementation?.requestNotificationsPermission();
        debugPrint('[NotificationService] Android permission granted: $granted');
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final bool? granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        debugPrint('[NotificationService] iOS permission granted: $granted');
      }
    } catch (e) {
      debugPrint('[NotificationService] ERROR requesting permissions: $e');
    }
  }
}
