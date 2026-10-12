import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final TextEditingController nameController =
      TextEditingController();
  final TextEditingController sectionController =
      TextEditingController();
  final TextEditingController yearLevelController =
      TextEditingController();

  final List<TextEditingController> subjectControllers =
      List.generate(3, (_) => TextEditingController());

  final List<TextEditingController> scheduleControllers =
      List.generate(3, (_) => TextEditingController());

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  bool showSchedulePage = false;
  bool isSaving = false;

  void nextPage() {
    if (nameController.text.trim().isEmpty ||
        sectionController.text.trim().isEmpty ||
        yearLevelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all student fields'),
        ),
      );
      return;
    }

    setState(() {
      showSchedulePage = true;
    });
  }

  Future<void> saveData() async {
    for (int i = 0; i < 3; i++) {
      if (subjectControllers[i].text.trim().isEmpty ||
          scheduleControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill in all subjects and schedules',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      await firestore.collection('student').add({
        'name': nameController.text.trim(),
        'section': sectionController.text.trim(),
        'yearLevel': yearLevelController.text.trim(),
        'subjects': List.generate(3, (i) => {
          'subject': subjectControllers[i].text.trim(),
          'schedule': scheduleControllers[i].text.trim(),
        }),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      nameController.clear();
      sectionController.clear();
      yearLevelController.clear();

      for (final controller in subjectControllers) {
        controller.clear();
      }

      for (final controller in scheduleControllers) {
        controller.clear();
      }

      setState(() {
        showSchedulePage = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    sectionController.dispose();
    yearLevelController.dispose();

    for (final controller in subjectControllers) {
      controller.dispose();
    }

    for (final controller in scheduleControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget buildField(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildScheduleField(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Subject ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),
            buildField(
              'Subject',
              subjectControllers[index],
            ),
            buildField(
              'Schedule',
              scheduleControllers[index],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          showSchedulePage
              ? 'Subject Schedule'
              : 'Student Registration',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!showSchedulePage) ...[
                  const Icon(
                    Icons.app_registration,
                    size: 65,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Student Registration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  buildField('Name', nameController),
                  buildField('Section', sectionController),
                  buildField('Yr. Level', yearLevelController),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Next'),
                  ),
                ] else ...[
                  const Icon(
                    Icons.calendar_month,
                    size: 65,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Subject Schedule',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student: ${nameController.text.trim()}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    3,
                    (index) => buildScheduleField(index),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isSaving ? null : saveData,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Save to Firebase'),
                  ),
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            setState(() {
                              showSchedulePage = false;
                            });
                          },
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}