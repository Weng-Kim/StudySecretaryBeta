import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:study_secretary_flutter_final/DatabaseHelper.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  Future<void> showMotivationalBanner(int userId) async {
    List<String> messages = [];
    // Create an instance of DatabaseHelper (if not static) and fetc
    DatabaseHelper dbHelper = DatabaseHelper();
    Map<String, String?> messageMap = await dbHelper.fetchRandomMessageAndGoal(userId);

    String? message = messageMap['message'];
    if (message != null && message.isNotEmpty) {
      messages.add(message);
    }

    if (messages.isEmpty) {
      messages = [
        "Keep pushing forward! 💪",
        "Success is built one session at a time. ⏳",
        "Stay focused! You got this! 🚀",
        "Believe in yourself and stay consistent. 🌟"
      ];
    }    final String randomMessage = messages[Random().nextInt(messages.length)];
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motivational_channel', 'Motivational Banners',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0, // Notification ID
      "Study Motivation 💡",
      randomMessage,
      notificationDetails,
    );
  }

  /*final String randomMessage = messages[Random().nextInt(messages.length)];

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'motivational_channel', 'Motivational Banners',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0, // Notification ID
      "Study Motivation 💡",
      randomMessage,
      notificationDetails,
    );
  }*/

  Future<void> showPomodoroNotification(bool isBreak) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pomodoro_channel', 'Pomodoro Timings',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      1,
      isBreak ? "Break Time! ☕" : "Focus Time! 📚",
      isBreak ? "Take a short break and recharge!" : "Time to focus and get things done!",
      notificationDetails,
    );
  }

  Future<void> showStudySessionNotification(int minutes) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_session_channel', 'Study Session',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      2,
      "Study Session Complete! ✅",
      "You studied for $minutes minutes! Great job! 🎉",
      notificationDetails,
    );
  }

  Future<void> scheduleExamReminder(String examName, DateTime examDate) async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(examDate.subtract(const Duration(days: 1)), tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'exam_reminder_channel', 'Exam Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      3,
      "Upcoming Exam Reminder!",
      "Don't forget! Your exam '$examName' is tomorrow.",
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
