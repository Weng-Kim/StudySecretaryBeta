import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:study_secretary_flutter_final/main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _notificationsEnabled = true; // Default state

  // Handle toggle switch change
  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });

    if (_notificationsEnabled) {
      await scheduleNotification(); // Enable notifications
    } else {
      await disableNotifications(); // Disable notifications
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SwitchListTile(
        title: const Text('Enable Notifications'),
        value: _notificationsEnabled,
        onChanged: _toggleNotifications,
      ),
    );
  }


  Future<void> scheduleNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Channel for default notifications',
      importance: Importance.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      0, // Notification ID
      'Test Notification',
      'Notifications are enabled!',
      notificationDetails,
    );
  }

  Future<void> disableNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}