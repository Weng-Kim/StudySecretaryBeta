import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:study_secretary_flutter_final/DatabaseHelper.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadExamDates();
    _loadStudySessions();
  }
  void _showStudySessionsPopup(DateTime selectedDate) {
    List<String> events = _getEventsForDay(selectedDate);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Events on ${selectedDate.toLocal()}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: events.isNotEmpty
                ? events.map((event) => ListTile(title: Text(event))).toList()
                : [const Text("No events")],
          ),
          actions: [
            TextButton(
              child: const Text("Add Study Session"),
              onPressed: () {
                Navigator.pop(context);
                _showAddStudySessionDialog(selectedDate);
              },
            ),
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showAddStudySessionDialog(DateTime selectedDate) {
    TextEditingController descriptionController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Study Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Date: ${selectedDate.toLocal()}".split(' ')[0]),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: "Time (HH:mm)"),
                keyboardType: TextInputType.datetime,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                if (timeController.text.isNotEmpty && descriptionController.text.isNotEmpty) {
                  await dbHelper.insertStudySession(
                    selectedDate.toIso8601String(),
                    selectedDate.toIso8601String(), // End date same as start date
                    timeController.text,
                    descriptionController.text,
                  );
                  _loadStudySessions(); // Refresh calendar
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _initializeNotifications() {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleNotification(String title, String body, DateTime scheduledTime) async {
    const androidDetails = AndroidNotificationDetails(
      'study_reminder',
      'Study Reminders',
      channelDescription: 'Reminders for study and exams',
      importance: Importance.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    // Convert `DateTime` to `TZDateTime`
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      0, // Notification ID
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Optional: for recurring notifications
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Use the appropriate mode
    );


  }

  Future<void> _loadExamDates() async {
    final exams = await dbHelper.fetchAllExams();
    Map<DateTime, List<String>> events = {};

    for (var exam in exams) {
      // Ensure examDate is in ISO-8601 format before parsing
      try {
        DateTime examDate = DateTime.parse(exam['examDate']);
        String examName = exam['name'] ?? exam['examTypeName'];
        if (events[examDate] == null) {
          events[examDate] = [];
        }
        events[examDate]!.add(examName);
      } catch (e) {
        print('Error parsing date: ${exam['examDate']}');
      }
    }

    setState(() {
      _events = events;
    });
  }
  Future<void> _loadStudySessions() async {
    final sessions = await dbHelper.fetchStudySessions();
    Map<DateTime, List<String>> events = {};

    for (var session in sessions) {
      try {
        DateTime studyDate = DateTime.parse(session['start_date']);
        String time = session['time']; // Get study session time
        String description = session['description'] ?? 'Study Session';

        if (events[studyDate] == null) {
          events[studyDate] = [];
        }
        events[studyDate]!.add('$description at $time'); // Show time with event
      } catch (e) {
        print('Error parsing study session date: ${session['start_date']}');
      }
    }

    setState(() {
      _events = events;
    });
  }


  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  void _addStudyReminder(DateTime day) async {
    final reminderTime = day.subtract(const Duration(hours: 1));
    await _scheduleNotification(
      "Study Reminder",
      "Prepare for exams scheduled on ${day.toLocal()}",
      reminderTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for ${day.toLocal()}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              _showStudySessionsPopup(selectedDay);
            },

            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8.0),
              ),
              formatButtonTextStyle: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (_selectedDay != null)
                  ..._getEventsForDay(_selectedDay!).map((event) => ListTile(
                    title: Text(event),
                    subtitle: Text('Exam Date: ${_selectedDay!.toLocal()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => _addStudyReminder(_selectedDay!),
                    ),
                  )),
                if (_selectedDay == null || _getEventsForDay(_selectedDay!).isEmpty)
                  const Center(child: Text('No events for the selected day')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}