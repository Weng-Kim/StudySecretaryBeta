import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'user_data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL, -- Store hashed passwords
            first_name TEXT NOT NULL,
            course_id INTEGER NOT NULL,
            exam_year INTEGER NOT NULL,
            FOREIGN KEY (course_id) REFERENCES courses(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE courses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE user_subjects(
            user_id INTEGER NOT NULL,
            subject TEXT NOT NULL,
            level TEXT NOT NULL CHECK(level IN ('SL', 'HL')),
            PRIMARY KEY (user_id, subject),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE user_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE user_goals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            goal TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE exams(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('predefined', 'custom')),
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            description TEXT,
            CHECK(start_date <= end_date)
          )
        ''');

        await db.execute(''' 
          CREATE TABLE studysesh(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            time TEXT NOT NULL,  -- 24-hour format (HH:mm)
            description TEXT,
            CHECK(start_date <= end_date)
          )
        ''');

        await db.execute('''
          CREATE TABLE syllabus (
            syllabus_id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT NOT NULL,
            course_id TEXT NOT NULL,
            level TEXT NOT NULL,
            chapter TEXT NOT NULL,
            UNIQUE(subject, course_id, level, chapter)
          );
        ''');

        await db.execute('''
          CREATE TABLE user_syllabus_progress (
            progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            syllabus_id INTEGER NOT NULL,
            is_completed BOOLEAN DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
            FOREIGN KEY (syllabus_id) REFERENCES syllabus(syllabus_id) ON DELETE CASCADE,
            UNIQUE(user_id, syllabus_id)  -- Ensures no duplicate progress for the same user & syllabus
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS study_time (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            total_time INTEGER NOT NULL  -- Time in seconds
          )
        ''');
        int? userId = await getUserId(db);
        if (userId == null) {
          userId = await db.insert('users', {'name': 'Default User'});
        }//create new user if none
        //await _insertPredefinedMessages(db, userId);
        await _insertPredefinedExams(db);
      },
    );
  }

  Future<int?> getUserId(Database db) async {
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['id'], // Get only user ID
      orderBy: 'id DESC', // Assuming the last user is the current user
      limit: 1, // Get the latest user
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int; // Return user ID
    }
    return null; // No user found
  }


  /*Future<void> _insertPredefinedMessages(Database db, int userId) async {
    final List<String> predefinedMessages = [
      "Keep pushing forward! 💪",
      "Success is built one session at a time. ⏳",
      "Stay focused! You got this! 🚀",
      "Believe in yourself and stay consistent. 🌟"
    ];

    for (String message in predefinedMessages) {
      await db.insert(
        'user_messages',
        {
          'user_id': userId,
          'message': message,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }*/

  Future<void> _insertPredefinedExams(Database db) async {
    final predefinedExamTypes = [
      {'name': 'IB May Session 2024', 'type': 'predefined', 'start_date': '2024-04-25', 'end_date': '2024-05-17', 'description': null},
      {'name': 'IB November Session 2024', 'type': 'predefined', 'start_date': '2024-10-21', 'end_date': '2024-11-11', 'description': null},
      {'name': 'A-Levels 2024', 'type': 'predefined', 'start_date': '2024-07-03', 'end_date': '2024-11-07', 'description': 'Oral is in July, Written papers start in October'},
      {'name': 'O-Levels 2024', 'type': 'predefined', 'start_date': '2024-07-03', 'end_date': '2024-11-11', 'description': 'Oral and Mother Tongue Listening is in July, Written papers start in October'},
    ];

    for (var exam in predefinedExamTypes) {
      await db.insert('exams', exam);
    }
  }

  Future<int> insertUser({
    required String username,
    required String passwordHash, // Store hashed password
    required String firstName,
    required String course, // Course should map to course_id
    required int examYear,
    required List<String> subjects,
    required List<String> levels,
    required List<String> messages,
    required List<String> goals,
  }) async {
    final db = await initDatabase();

    // Find or insert the course and get its ID
    int? courseId;
    final courseQuery = await db.query('courses', where: 'name = ?', whereArgs: [course]);

    if (courseQuery.isEmpty) {
      courseId = await db.insert('courses', {'name': course});
    } else {
      courseId = courseQuery.first['id'] as int;
    }

    // Insert user
    final userId = await db.insert('users', {
      'username': username,
      'password_hash': passwordHash, // Store hashed password
      'first_name': firstName,
      'course_id': courseId,
      'exam_year': examYear,
    });

    // Insert user subjects
    for (int i = 0; i < subjects.length; i++) {
      await db.insert('user_subjects', {
        'user_id': userId,
        'subject': subjects[i],
        'level': levels[i],
      });
    }

    // Insert user messages
    for (var message in messages) {
      await db.insert('user_messages', {
        'user_id': userId,
        'message': message,
      });
    }

    // Insert user goals
    for (var goal in goals) {
      await db.insert('user_goals', {
        'user_id': userId,
        'goal': goal,
      });
    }

    return userId;
  }


  Future<List<Map<String, dynamic>>> fetchAllExams() async {
    final db = await initDatabase();

    try {
      return await db.query('exams');
    } catch (e) {
      print('Error fetching exams: $e');
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> fetchProfile(int userId) async {
    final db = await initDatabase();

    // Fetch user details
    final userData = await db.query('users', where: 'id = ?', whereArgs: [userId]);

    if (userData.isEmpty) return [];

    // Fetch subjects and levels
    final subjects = await db.query('user_subjects', where: 'user_id = ?', whereArgs: [userId]);

    // Fetch messages
    final messages = await db.query('user_messages', where: 'user_id = ?', whereArgs: [userId]);

    // Fetch goals
    final goals = await db.query('user_goals', where: 'user_id = ?', whereArgs: [userId]);

    return [
      {
        'user': userData.first,
        'subjects': subjects,
        'messages': messages.map((m) => m['message']).toList(),
        'goals': goals.map((g) => g['goal']).toList(),
      }
    ];
  }

  Future<Map<String, String?>> fetchRandomMessageAndGoal(userID) async {
    final db = await initDatabase();
    int? userId = await getUserId(db);
    if (userId == null) {
      userId = await db.insert('users', {'name': 'Default User'});
    } // If no user exists, create one
    final messages = await db.query('user_messages', where: 'user_id = ?', whereArgs: [userId]);
    final goals = await db.query('user_goals', where: 'user_id = ?', whereArgs: [userId]);

    if (messages.isEmpty || goals.isEmpty) return {'message': null, 'goal': null};

    return {
      'message': messages[Random().nextInt(messages.length)]['message'] as String?,
      'goal': goals[Random().nextInt(goals.length)]['goal'] as String?,
    };
  }
  Future<int?> getLoggedInUserId() async {
    final db = await initDatabase();
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      columns: ['user_id'],
      where: 'logged_in = ?',
      whereArgs: [1], //boolean tracking
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['user_id'] as int;
    }
    return null;
  }


  Future<void> insertCustomExam({
    required String name,
    required String startDate,
    required String endDate,
    String? description,
  }) async {
    final db = await initDatabase();
    await db.insert('exams', {
      'name': name,
      'type': 'custom',
      'start_date': startDate,
      'end_date': endDate,
      'description': description ?? '',
    });
  }

  Future<int> insertStudySession(String startDate, String endDate, String time, String description) async {
    final db = await initDatabase();
    return await db.insert(
      'studysesh',
      {
        'start_date': startDate,
        'end_date': endDate,
        'time': time,
        'description': description,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchStudySessions() async {
    final db = await initDatabase();
    return await db.query('studysesh');
  }

  Future<int> updateStudySession(int id, String startDate, String endDate, String time, String description) async {
    final db = await initDatabase();
    return await db.update(
      'studysesh',
      {
        'start_date': startDate,
        'end_date': endDate,
        'time': time,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> logStudyTime(int durationInSeconds) async {
    final db = await initDatabase();
    String today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      'study_time',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (result.isEmpty) {
      await db.insert('study_time', {'date': today, 'total_time': durationInSeconds});
    } else {
      int currentTotal = result.first['total_time'] as int;
      await db.update(
        'study_time',
        {'total_time': currentTotal + durationInSeconds},
        where: 'date = ?',
        whereArgs: [today],
      );
    }
  }

  Future<int> getTotalStudyTime() async {
    final db = await initDatabase();
    String today = DateTime.now().toIso8601String().split('T')[0];

    final result = await db.query(
      'study_time',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (result.isEmpty) return 0;
    return result.first['total_time'] as int;
  }


}
