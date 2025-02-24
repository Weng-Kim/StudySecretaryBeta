import 'package:flutter/material.dart';
import 'package:study_secretary_flutter_final/ExamScheduleScreen.dart';
import 'DatabaseHelper.dart'; // Import the database helper
//import 'NotificationService.dart';

class AddYourExams extends StatefulWidget {
  const AddYourExams({super.key});

  @override
  _AddYourExamsState createState() => _AddYourExamsState(); // Corrected state class
}

class _AddYourExamsState extends State<AddYourExams> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper(); // Initialize database helper

  // Text input controllers for `custom_exams`
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _examDescriptionController = TextEditingController();

  Future<void> _saveExamData() async {
    if (_formKey.currentState!.validate()) {
      String name = _examNameController.text;
      String startDate = _startDateController.text;
      String endDate = _endDateController.text;
      String description = _examDescriptionController.text;

      // Save to `custom_exams` table
      await dbHelper.insertCustomExam(
        name: name,
        startDate: startDate,
        endDate: endDate,
        description: description,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam data saved!')),
      );
    }
  }

  @override
  void dispose() {
    _examNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _examDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Your Exam'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                // Exam Name field
                TextFormField(
                  controller: _examNameController,
                  decoration: const InputDecoration(labelText: 'Exam Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the exam name';
                    }
                    return null;
                  },
                ),

                // Exam Start Date field
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(labelText: 'Start Date (dd/mm/yyyy)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the exam start date';
                    }
                    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!dateRegex.hasMatch(value)) {
                      return 'Enter a valid date (dd/mm/yyyy)';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.datetime,
                ),

                // Exam End Date field
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(labelText: 'End Date (dd/mm/yyyy)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the exam end date';
                    }
                    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                    if (!dateRegex.hasMatch(value)) {
                      return 'Enter a valid date (dd/mm/yyyy)';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.datetime,
                ),

                // Exam Description field
                TextFormField(
                  controller: _examDescriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _saveExamData(); // Save data to the database
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Exam added successfully!')),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ExamScheduleScreen()),
                      );
                    }
                  },
                  child: const Text('Add this Exam'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
