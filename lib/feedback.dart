import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackScreen extends StatefulWidget {
  final String conversationId;

  const FeedbackScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int? patientRating;
  int? medicRating;
  final TextEditingController patientCommentsController = TextEditingController();
  final TextEditingController medicCommentsController = TextEditingController();

  Future<void> submitFeedback() async {
    final response = await http.post(
      Uri.parse('http://0.0.0.0:8001/feedback'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversation_id': widget.conversationId,
        'patient_rating': patientRating,
        'medic_rating': medicRating,
        'patient_comment': patientCommentsController.text,
        'medic_comment': medicCommentsController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate the conversation',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Patient Rating:'),
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                Icons.star,
                                color: (patientRating != null && patientRating! > index)
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  patientRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Text('Medic Rating:'),
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                Icons.star,
                                color: (medicRating != null && medicRating! > index)
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  medicRating = index + 1;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        const Text('Patient Comments:'),
                        TextField(
                          controller: patientCommentsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter patient comments here...',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Medic Comments:'),
                        TextField(
                          controller: medicCommentsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter medic comments here...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text('Submit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: const Text('Skip',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
