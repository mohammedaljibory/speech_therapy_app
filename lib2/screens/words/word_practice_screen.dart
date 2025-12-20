import 'package:flutter/material.dart';

class WordPracticeScreen extends StatelessWidget {
  final String wordId;
  final String childId;

  const WordPracticeScreen({
    super.key,
    required this.wordId,
    required this.childId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تمرين النطق')),
      body: const Center(child: Text('Word Practice Screen - Coming Soon')),
    );
  }
}
