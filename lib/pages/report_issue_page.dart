import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme/theme_colors.dart';

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({Key? key}) : super(key: key);

  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final TextEditingController _descriptionController = TextEditingController();
  String _reportType = 'Misinformation';
  List<Map<String, dynamic>> _feedbackList = [];
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  void _submitReport() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to submit feedback.')),
      );
      return;
    }

    final uid = user!.uid;
    final email = user!.email ?? 'Anonymous';

    final DatabaseReference userRef =
    FirebaseDatabase.instance.ref('Feedback/$uid');

    await userRef.push().set({
      'Type': _reportType,
      'Message': _descriptionController.text,
      'UserEmail': email,
      'Timestamp': DateTime.now().toIso8601String(),
    });

    _descriptionController.clear();
    _loadFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully!')),
    );
  }

  void _loadFeedback() async {
    if (user == null) return;

    final uid = user!.uid;
    final userRef = FirebaseDatabase.instance.ref('Feedback/$uid');

    final snapshot = await userRef.get();

    if (snapshot.exists) {
      final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      final List<Map<String, dynamic>> feedbacks = [];

      data.forEach((key, value) {
        if (value is Map) {
          feedbacks.add({
            'Type': value['Type'] ?? 'N/A',
            'Message': value['Message'] ?? '',
            'UserEmail': value['UserEmail'],
            'Timestamp': value['Timestamp'] ?? '',
          });
        }
      });

      setState(() {
        _feedbackList = feedbacks.reversed.toList(); // most recent first
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColor.background,
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: ThemeColor.background,
        foregroundColor: ThemeColor.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _reportType,
              dropdownColor: ThemeColor.background,
              style: TextStyle(color: ThemeColor.textPrimary),
              onChanged: (String? newValue) {
                setState(() {
                  _reportType = newValue ?? _reportType;
                });
              },
              items: <String>['Misinformation', 'Bugs', 'Missing Feature']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: ThemeColor.textPrimary)),
                );
              }).toList(),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: ThemeColor.textPrimary),
                hintText: 'Describe your issue or feedback',
                hintStyle: TextStyle(color: ThemeColor.textSecondary),
              ),
              maxLines: 5,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColor.secondary,
              ),
              onPressed: _submitReport,
              child: Text('Submit Report', style: TextStyle(color: ThemeColor.textPrimary)),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Text(
              'Your Previous Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThemeColor.textPrimary),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _feedbackList.isEmpty
                  ? Text("No feedback submitted yet.", style: TextStyle(color: ThemeColor.textSecondary))
                  : ListView.builder(
                itemCount: _feedbackList.length,
                itemBuilder: (context, index) {
                  final report = _feedbackList[index];
                  return Card(
                    color: ThemeColor.primary.withOpacity(0.9),
                    child: ListTile(
                      title: Text(report['Type'], style: TextStyle(color: ThemeColor.textPrimary)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Message: ${report['Message']}"),
                          Text("Email: ${report['UserEmail']}"),
                          Text("Time: ${report['Timestamp']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
