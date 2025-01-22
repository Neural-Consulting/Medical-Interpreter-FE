import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'conversation.dart';

void main() {
  runApp(const TranslationApp());
}

class TranslationApp extends StatelessWidget {
  const TranslationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Translator',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.indigo[700],
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
      ),
      home: const StartConversationScreen(),
    );
  }
}

class StartConversationScreen extends StatefulWidget {
  const StartConversationScreen({super.key});

  @override
  _StartConversationScreenState createState() => _StartConversationScreenState();
}

class _StartConversationScreenState extends State<StartConversationScreen> {
  String professionalLanguage = 'Danish';
  String patientLanguage = 'English';
  final List<String> languages = ['Danish', 'English', 'German', 'Turkish', 'Arabic', 'Ukrainian', 'Persian', 'Romanian'];
  String? conversationId;

  Future<void> startConversation() async {
    final response = await http.post(
      Uri.parse('http://0.0.0.0:8001/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'medic_language': professionalLanguage,
        'patient_language': patientLanguage,
      }),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      conversationId = responseData['conversation_id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(conversationId: conversationId!,
            professionalLanguage: professionalLanguage, patientLanguage: patientLanguage),
        ),
      );
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
                        const Text(
                          'Select Languages',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: professionalLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Professional Language',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              professionalLanguage = newValue!;
                            });
                          },
                          items: languages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: patientLanguage,
                          decoration: const InputDecoration(
                            labelText: 'Patient Language',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              patientLanguage = newValue!;
                            });
                          },
                          items: languages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: startConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text('Start Conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}