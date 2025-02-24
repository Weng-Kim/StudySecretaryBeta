import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SyllabusChecklist extends StatefulWidget {
  const SyllabusChecklist({super.key});

  @override
  _SyllabusChecklistState createState() => _SyllabusChecklistState();
}

class _SyllabusChecklistState extends State<SyllabusChecklist> {
  List<Map<String, dynamic>> _syllabus = [];
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user_data.db'), // Unified DB
      onCreate: (db, version) {
        return db.execute(
          """
          CREATE TABLE IF NOT EXISTS User_Syllabus_Progress (
            progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            syllabus_id INTEGER NOT NULL,
            completed BOOLEAN DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
            FOREIGN KEY (syllabus_id) REFERENCES syllabus(syllabus_id) ON DELETE CASCADE,
            UNIQUE(user_id, syllabus_id)
          )
          """,
        );
      },
      version: 1,
    );
    _loadSyllabus();
  }

  Future<void> _loadSyllabus() async {
    final List<Map<String, dynamic>> maps = await _database!.rawQuery('''
      SELECT usp.progress_id, usp.completed, s.subject, s.chapter
      FROM User_Syllabus_Progress usp
      JOIN syllabus s ON usp.syllabus_id = s.syllabus_id
    ''');

    setState(() {
      _syllabus = maps;
    });
  }

  Future<void> _toggleCompletion(int id, bool completed) async {
    await _database!.update(
      'User_Syllabus_Progress',
      {'completed': completed ? 1 : 0},
      where: 'progress_id = ?',
      whereArgs: [id],
    );
    _loadSyllabus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Syllabus Checklist")),
      body: _syllabus.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _syllabus.length,
        itemBuilder: (context, index) {
          return CheckboxListTile(
            title: Text("${_syllabus[index]['subject']} - ${_syllabus[index]['chapter']}"),
            value: _syllabus[index]['completed'] == 1,
            onChanged: (bool? value) {
              _toggleCompletion(_syllabus[index]['progress_id'], value!);
            },
          );
        },
      ),
    );
  }
}
