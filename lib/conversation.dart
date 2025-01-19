import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'feedback.dart';

class ConversationScreen extends StatefulWidget {
  final String conversationId;
  final String professionalLanguage;
  final String patientLanguage;

  const ConversationScreen({
    Key? key,
    required this.conversationId,
    required this.professionalLanguage,
    required this.patientLanguage,
  }) : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  Uint8List? audioBytes;
  bool isRecording = false;
  bool isListeningOverlayVisible = false;
  bool isLoading = false;
  String? activeButton;
  final List<Map<String, String>> conversationHistory = [];
  final ScrollController _scrollController = ScrollController();
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _audioChunks = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> startRecording(String buttonType) async {
    setState(() {
      isRecording = true;
      isListeningOverlayVisible = true;
      activeButton = buttonType;
      audioBytes = null;
    });

    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (stream != null) {
        _mediaRecorder = html.MediaRecorder(stream, {'mimeType': 'audio/webm'});
        _audioChunks = [];

        _mediaRecorder?.addEventListener('dataavailable', (event) {
          final blobEvent = event as html.BlobEvent;
          if (blobEvent.data != null) {
            _audioChunks.add(blobEvent.data!); // Ensure `data` is not null
          } else {
            debugPrint("No data available in the event.");
          }
        });

        _mediaRecorder?.start();
        debugPrint("Recording started");
      } else {
        throw Exception("Unable to access microphone");
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      setState(() {
        isRecording = false;
        isListeningOverlayVisible = false;
      });
    }
  }

  Future<void> stopRecording(String speakerType) async {
    if (_mediaRecorder != null && isRecording) {
      try {
        _mediaRecorder?.stop();

        _mediaRecorder?.addEventListener('stop', (_) async {
          final audioBlob = html.Blob(_audioChunks);
          final reader = html.FileReader();

          reader.readAsArrayBuffer(audioBlob);
          reader.onLoadEnd.listen((_) async {
            audioBytes = reader.result as Uint8List;

            setState(() {
              isRecording = false;
              isListeningOverlayVisible = false;
              activeButton = null;
              isLoading = true;
            });

            final response = await http.post(
              Uri.parse('http://0.0.0.0:8001/interact'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'conversation_id': widget.conversationId,
                'individual': speakerType,
                'audio': base64Encode(audioBytes!),
              }),
            );

            setState(() {
              isLoading = false;
            });

            if (response.statusCode == 200) {
              final responseData = jsonDecode(utf8.decode(response.bodyBytes));
              setState(() {
                conversationHistory.add({
                  'speaker': responseData['individual'] ?? 'Unknown',
                  'content_reciever': responseData['content_reciever'] ?? 'No content',
                  'content_sender': responseData['content_sender'] ?? 'No additional information',
                  'id': DateTime.now().toString(),
                });
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${response.body}')),
              );
            }
          });
        });
      } catch (e) {
        debugPrint("Error stopping recording: $e");
        setState(() {
          isRecording = false;
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo, Colors.blueAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(55, 255, 255, 255),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: conversationHistory.length,
                        itemBuilder: (context, index) {
                          final entry = conversationHistory[index];
                          final isPatient = entry['speaker'] == 'patient';
                          return Column(
                            crossAxisAlignment:
                                isPatient ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPatient ? 'Patient' : 'Medic',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Align(
                                alignment:
                                    isPatient ? Alignment.topRight : Alignment.topLeft,
                                child: Container(
                                  margin: EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                    left: isPatient ? 40 : 0,
                                    right: isPatient ? 0 : 40,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry['content_reciever']!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry['content_sender']!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => startRecording('medic'),
                          onLongPressUp: () => stopRecording('medic'),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.mic, size: 24, color: Colors.white),
                            label: const Text('Medic'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeButton == 'medic'
                                  ? Colors.lightBlue
                                  : const Color.fromARGB(255, 53, 67, 108),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              minimumSize: const Size.fromHeight(60),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () => startRecording('patient'),
                          onLongPressUp: () => stopRecording('patient'),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.mic, size: 24, color: Colors.white),
                            label: const Text('Patient'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: activeButton == 'patient'
                                  ? Colors.lightBlue
                                  : const Color.fromARGB(255, 53, 67, 108),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              minimumSize: const Size.fromHeight(60),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FeedbackScreen(conversationId: widget.conversationId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(60),
                    ),
                    child: const Text('End Conversation'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing Translation...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnimatedOpacity(
            opacity: isListeningOverlayVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(215, 255, 255, 255),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.multitrack_audio,
                      size: 40,
                      color: const Color.fromARGB(255, 82, 90, 139),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Listening',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
