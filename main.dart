import 'package:flutter/material.dart';
import 'package:study_secretary_flutter_final/Home.dart';
import 'package:study_secretary_flutter_final/UserDataForm.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_secretary_flutter_final/DatabaseHelper.dart';
import 'package:study_secretary_flutter_final/NotificationService.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
//import 'notification_service.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initNotifications();

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // TextEditingController to capture the username and password from the input fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Function to fetch user data by username from the database
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final Database db = await DatabaseHelper().initDatabase();

    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // Function to handle login logic
  Future<void> _login() async {
    // Fetching values from the TextEditingController (i.e., from the input fields)
    String inputUsername = _usernameController.text;
    String inputPassword = _passwordController.text;

    final user = await getUserByUsername(inputUsername);

    if (user != null) {
      String dbPassword = user['password'];

      if (dbPassword == inputPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid password')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
    }
  }

  Future<bool> verifyUser(String username, String enteredPassword) async {
    final dbHelper = DatabaseHelper(); // Create an instance
    final db = await dbHelper.initDatabase(); // Call initDatabase on the instance

    String enteredPasswordHash = sha256.convert(utf8.encode(enteredPassword)).toString();

    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isNotEmpty) {
      String storedPasswordHash = result.first['password_hash'];
      return enteredPasswordHash == storedPasswordHash; // Compare hashes
    }

    return false;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Welcome to Study Secretary!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Please enter your login credentials.',
              style: TextStyle(fontSize: 18),
            ),
            // Username input field
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            // Password input field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Login button that triggers the _login method
            ElevatedButton(
              onPressed: () {
                _login(); // Calling the _login method when login button is pressed
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 20),
            // Create Account button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserDataForm()),
                );
                print('Create Account button pressed');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Create Account'),
            ),
            const SizedBox(width: 20),
            // Forgot Password button
            ElevatedButton(
              onPressed: () {
                print('Forgot Password button pressed');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Forgot Password'),
            ),
          ],
        ),
      ),
    );
  }
}