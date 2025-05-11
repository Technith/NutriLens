import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

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
      appBar: AppBar(
        title: const Text('Report Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _reportType,
              onChanged: (String? newValue) {
                setState(() {
                  _reportType = newValue ?? _reportType;
                });
              },
              items: <String>['Misinformation', 'Bugs', 'Missing Feature']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your issue or feedback',
              ),
              maxLines: 5,
            ),
            ElevatedButton(
              onPressed: _submitReport,
              child: const Text('Submit Report'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Your Previous Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _feedbackList.isEmpty
                  ? const Text("No feedback submitted yet.")
                  : ListView.builder(
                itemCount: _feedbackList.length,
                itemBuilder: (context, index) {
                  final report = _feedbackList[index];
                  return Card(
                    child: ListTile(
                      title: Text(report['Type']),
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
