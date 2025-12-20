import 'package:flutter/material.dart';

class RecordingScreen extends StatelessWidget {
  final String wordId;
  final String childId;
  final String correctPronunciationUrl;

  const RecordingScreen({
    super.key,
    required this.wordId,
    required this.childId,
    required this.correctPronunciationUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل')),
      body: const Center(child: Text('Recording Screen - Coming Soon')),
    );
  }
}
