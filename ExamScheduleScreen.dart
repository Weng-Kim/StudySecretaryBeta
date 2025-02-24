import 'package:flutter/material.dart';
import 'package:study_secretary_flutter_final/DatabaseHelper.dart';
import 'AddYourExams.dart';

class ExamScheduleScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  ExamScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Schedule')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchExamSchedule(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading exam schedule.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No exams found. Add your school examinations.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddYourExams()),
                      );
                    },
                    child: const Text('Add Exam'),
                  ),
                ],
              ),
            );
          }

          final exams = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final examName = exam['name'] ?? exam['examTypeName']; // Custom or predefined
              final examDate = exam['examDate'];

              return ListTile(
                title: Text(examName),
                subtitle: Text('Exam Date: $examDate'),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchExamSchedule() async {
    return await dbHelper.fetchAllExams();
  }
}