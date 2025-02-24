import 'package:flutter/material.dart';
import 'package:study_secretary_flutter_final/PomodoroTimer.dart';
import 'package:study_secretary_flutter_final/ExamScheduleScreen.dart';
import 'package:study_secretary_flutter_final/Calendar.dart';
import 'package:study_secretary_flutter_final/Profile.dart';
import 'package:study_secretary_flutter_final/DatabaseHelper.dart';
import 'package:study_secretary_flutter_final/SyllabusChecklist.dart';
import 'Settings.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.pink,
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Home(),
                  ),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
                onTap: () async {
                  final dbHelper = DatabaseHelper();
                  int? userId = await dbHelper.getLoggedInUserId(); // Fetch userId from database

                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Profile(userId: userId)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not found. Please log in again.')),
                    );
                  }
                }

            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Settings()),
                );                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        //Mainpage
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Study Secretary!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PomodoroTimer()),
                );
              },
              child: const Text('Study Now.'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Calendar()),
                );
              },
              child: const Text('Calendar'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExamScheduleScreen()),
                );
              },
              child: const Text('See your Exams'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SyllabusChecklist()),
                );
              },
              child: const Text('See your Study Progress'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}